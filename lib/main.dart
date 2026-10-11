import 'package:flutter/material.dart';

void main() {
  runApp(const PeachyCalculator());
}

class PeachyCalculator extends StatefulWidget {
  const PeachyCalculator({super.key});

  @override
  State<PeachyCalculator> createState() => _PeachyCalculatorState();
}

class _PeachyCalculatorState extends State<PeachyCalculator> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Peachy Calc',
      home: CalculatorPage(
        isDark: isDark,
        onThemeChanged: () {
          setState(() {
            isDark = !isDark;
          });
        },
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeChanged;

  const CalculatorPage({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String display = '0';
  String expression = 'Ready when you are!';
  String? pendingOperator;

  double? accumulator;

  bool waitingForNumber = false;
  bool finishedCalculation = false;
  bool hasError = false;

  final List<List<String>> buttons = [
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '−'],
    ['AC', '0', '=', '+'],
  ];

  Color get backgroundColor =>
      widget.isDark ? const Color(0xFF20202A) : const Color(0xFFFFF8F1);

  Color get cardColor => widget.isDark ? const Color(0xFF30303D) : Colors.white;

  Color get textColor =>
      widget.isDark ? const Color(0xFFF8F3F0) : const Color(0xFF383544);

  Color get softTextColor =>
      widget.isDark ? const Color(0xFFB8B4C5) : const Color(0xFF938C9B);

  Color get numberColor =>
      widget.isDark ? const Color(0xFF3A3A49) : const Color(0xFFF5F0EE);

  Color get operatorColor =>
      widget.isDark ? const Color(0xFF51445F) : const Color(0xFFECE3F8);

  Color get accentColor => const Color(0xFFEF947F);

  void resetCalculator() {
    display = '0';
    expression = 'Ready when you are!';
    pendingOperator = null;
    accumulator = null;
    waitingForNumber = false;
    finishedCalculation = false;
    hasError = false;
  }

  String formatNumber(double number) {
    if (!number.isFinite) {
      return 'Error';
    }

    if (number == 0) {
      return '0';
    }

    if (number == number.truncateToDouble() && number.abs() < 1000000000000) {
      return number.toInt().toString();
    }

    String result = number.toStringAsPrecision(10);

    if (result.contains('e') || result.contains('E')) {
      return result;
    }

    if (result.contains('.')) {
      result = result.replaceFirst(RegExp(r'0+$'), '');
      result = result.replaceFirst(RegExp(r'\.$'), '');
    }

    return result;
  }

  double? calculate(double first, double second, String operation) {
    double result;

    switch (operation) {
      case '+':
        result = first + second;
        break;
      case '−':
        result = first - second;
        break;
      case '×':
        result = first * second;
        break;
      case '÷':
        if (second == 0) {
          return null;
        }
        result = first / second;
        break;
      default:
        return null;
    }

    if (!result.isFinite) {
      return null;
    }

    return result;
  }

  void showError() {
    display = 'Error';
    expression = 'Oops! Cannot divide by zero';
    accumulator = null;
    pendingOperator = null;
    waitingForNumber = false;
    finishedCalculation = false;
    hasError = true;
  }

  void enterNumber(String number) {
    setState(() {
      if (hasError || finishedCalculation) {
        resetCalculator();
      }

      if (waitingForNumber) {
        display = number;
        waitingForNumber = false;
      } else if (display == '0') {
        display = number;
      } else if (display.length < 12) {
        display += number;
      }

      if (pendingOperator != null && accumulator != null) {
        expression = '${formatNumber(accumulator!)} $pendingOperator $display';
      } else {
        expression = 'Keep going, you got this!';
      }
    });
  }

  void selectOperator(String operator) {
    setState(() {
      if (hasError) {
        return;
      }

      if (waitingForNumber) {
        pendingOperator = operator;
        expression = '${formatNumber(accumulator ?? 0)} $pendingOperator';
        return;
      }

      double currentNumber = double.tryParse(display) ?? 0;

      if (finishedCalculation) {
        accumulator = currentNumber;
        finishedCalculation = false;
      } else if (pendingOperator != null && accumulator != null) {
        double? result = calculate(
          accumulator!,
          currentNumber,
          pendingOperator!,
        );

        if (result == null) {
          showError();
          return;
        }

        accumulator = result;
        display = formatNumber(result);
      } else {
        accumulator = currentNumber;
      }

      pendingOperator = operator;
      waitingForNumber = true;

      expression = '${formatNumber(accumulator!)} $pendingOperator';
    });
  }

  void pressEquals() {
    setState(() {
      if (hasError ||
          pendingOperator == null ||
          accumulator == null ||
          waitingForNumber) {
        return;
      }

      double? currentNumber = double.tryParse(display);

      if (currentNumber == null) {
        showError();
        return;
      }

      String oldExpression =
          '${formatNumber(accumulator!)} $pendingOperator $display';

      double? result = calculate(accumulator!, currentNumber, pendingOperator!);

      if (result == null) {
        showError();
        return;
      }

      display = formatNumber(result);
      expression = '$oldExpression =';

      accumulator = null;
      pendingOperator = null;
      waitingForNumber = false;
      finishedCalculation = true;
    });
  }

  void handleButton(String value) {
    if (value == 'AC') {
      setState(() {
        resetCalculator();
      });
    } else if (value == '=') {
      pressEquals();
    } else if (['+', '−', '×', '÷'].contains(value)) {
      selectOperator(value);
    } else {
      enterNumber(value);
    }
  }

  Widget buildCalculatorButton(String value) {
    bool isOperator = ['+', '−', '×', '÷'].contains(value);
    bool isEqual = value == '=';
    bool isClear = value == 'AC';

    Color buttonColor = numberColor;
    Color buttonTextColor = textColor;

    if (isOperator) {
      buttonColor = operatorColor;
      buttonTextColor = widget.isDark
          ? const Color(0xFFE2CCFA)
          : const Color(0xFF8060A0);
    }

    if (isEqual) {
      buttonColor = accentColor;
      buttonTextColor = Colors.white;
    }

    if (isClear) {
      buttonColor = widget.isDark
          ? const Color(0xFF62434A)
          : const Color(0xFFFFE1D8);

      buttonTextColor = widget.isDark
          ? const Color(0xFFFFC6BA)
          : const Color(0xFFD47766);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: buttonColor,
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: () => handleButton(value),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isClear ? 20 : 26,
                  fontWeight: isEqual ? FontWeight.bold : FontWeight.w600,
                  color: buttonTextColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFDDD3),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Color(0xFFE58A77),
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'peachy calc',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'your little math buddy',
                style: TextStyle(color: softTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
        Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onThemeChanged,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                widget.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                color: widget.isDark
                    ? const Color(0xFFFFD18B)
                    : const Color(0xFF8F79AF),
                size: 23,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.08 : 0.035),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF484254)
                      : const Color(0xFFF2EAF9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'CALCULATOR 01',
                  style: TextStyle(
                    color: widget.isDark
                        ? const Color(0xFFDFC8F2)
                        : const Color(0xFF9A7DB8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Icon(
                Icons.auto_awesome_rounded,
                color: const Color(0xFFEFAD91),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                expression,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: hasError ? const Color(0xFFEA8277) : softTextColor,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 53,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                    color: hasError ? const Color(0xFFEA8277) : textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              hasError
                  ? 'Press AC to start over'
                  : pendingOperator != null
                  ? 'Running total: ${formatNumber(accumulator ?? 0)}'
                  : finishedCalculation
                  ? 'Nice work!'
                  : 'One step at a time',
              style: TextStyle(
                color: softTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildKeypad() {
    return Column(
      children: buttons.map((row) {
        return Expanded(
          child: Row(
            children: row.map((value) {
              return buildCalculatorButton(value);
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  buildHeader(),
                  const SizedBox(height: 20),
                  Expanded(flex: 4, child: buildDisplay()),
                  const SizedBox(height: 17),
                  Expanded(flex: 7, child: buildKeypad()),
                  const SizedBox(height: 10),
                  Text(
                    'made with love & a little math',
                    style: TextStyle(fontSize: 11, color: softTextColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
