import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// ------------------------------------------------------------
/// API PRINCIPAL
/// ------------------------------------------------------------

Future<DateTime?> showERPDatePickerSingle({
  required BuildContext context,
  required DateTime initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => ERPDatePickerDialog(
      mode: ERPDatePickerMode.single,
      initialDate: initialDate,
    ),
  );
}

Future<(DateTime?, DateTime?)?> showERPDatePickerRange({
  required BuildContext context,
  required DateTime? from,
  required DateTime? to,
}) {
  return showDialog<(DateTime?, DateTime?)>(
    context: context,
    builder: (_) => ERPDatePickerDialog(
      mode: ERPDatePickerMode.range,
      initialDate: from ?? DateTime.now(),
      rangeFrom: from,
      rangeTo: to,
    ),
  );
}

/// ------------------------------------------------------------
/// ENUM
/// ------------------------------------------------------------

enum ERPDatePickerMode { single, range }

/// ------------------------------------------------------------
/// INTENTS PARA TECLADO
/// ------------------------------------------------------------

class DirectionIntent extends Intent {
  final int offset;
  const DirectionIntent(this.offset);
}

class MonthIntent extends Intent {
  final int offset;
  const MonthIntent(this.offset);
}

class YearIntent extends Intent {
  final int offset;
  const YearIntent(this.offset);
}

class AcceptIntent extends Intent {
  const AcceptIntent();
}

class CancelIntent extends Intent {
  const CancelIntent();
}

/// ------------------------------------------------------------
/// DIALOG PRINCIPAL
/// ------------------------------------------------------------

class ERPDatePickerDialog extends StatefulWidget {
  final ERPDatePickerMode mode;
  final DateTime initialDate;

  final DateTime? rangeFrom;
  final DateTime? rangeTo;

  const ERPDatePickerDialog({
    super.key,
    required this.mode,
    required this.initialDate,
    this.rangeFrom,
    this.rangeTo,
  });

  @override
  State<ERPDatePickerDialog> createState() => _ERPDatePickerDialogState();
}

class _ERPDatePickerDialogState extends State<ERPDatePickerDialog> {
  final fmt = DateFormat('dd/MM/yyyy', 'es_CR');

  late DateTime visibleMonth;

  // SINGLE
  late DateTime selected;

  // RANGE
  DateTime? from;
  DateTime? to;

  late TextEditingController ctrlSingle;
  late TextEditingController ctrlFrom;
  late TextEditingController ctrlTo;

  @override
  void initState() {
    super.initState();

    visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);

    if (widget.mode == ERPDatePickerMode.single) {
      selected = widget.initialDate;
      ctrlSingle = TextEditingController(text: fmt.format(selected));
    } else {
      from = widget.rangeFrom;
      to = widget.rangeTo;

      ctrlFrom = TextEditingController(
        text: from != null ? fmt.format(from!) : "",
      );
      ctrlTo = TextEditingController(
        text: to != null ? fmt.format(to!) : "",
      );
    }
  }

  DateTime? _parse(String text) {
    if (text.length != 10) return null;
    try {
      return fmt.parseStrict(text);
    } catch (_) {
      return null;
    }
  }

  void _moveDays(int offset) {
    setState(() {
      if (widget.mode == ERPDatePickerMode.single) {
        selected = selected.add(Duration(days: offset));
        visibleMonth = DateTime(selected.year, selected.month);
      } else {
        if (from == null) from = DateTime.now();
        from = from!.add(Duration(days: offset));
        visibleMonth = DateTime(from!.year, from!.month);
        ctrlFrom.text = fmt.format(from!);
      }
    });
  }

  void _moveMonths(int offset) {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + offset);
    });
  }

  void _moveYears(int offset) {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year + offset, visibleMonth.month);
    });
  }

  void _accept() {
    if (widget.mode == ERPDatePickerMode.single) {
      Navigator.pop(context, selected);
    } else {
      Navigator.pop(context, (from, to));
    }
  }

  void _prevMonth() => _moveMonths(-1);
  void _nextMonth() => _moveMonths(1);

  @override
  Widget build(BuildContext context) {
    final fmtHeader = DateFormat('MMMM yyyy', 'es_CR');

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 320,
          maxHeight: 350,
        ),
        child: Focus(
          autofocus: true,
          child: Shortcuts(
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DirectionIntent(-1),
              LogicalKeySet(LogicalKeyboardKey.arrowRight): const DirectionIntent(1),
              LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionIntent(-7),
              LogicalKeySet(LogicalKeyboardKey.arrowDown): const DirectionIntent(7),

              LogicalKeySet(LogicalKeyboardKey.pageUp): const MonthIntent(-1),
              LogicalKeySet(LogicalKeyboardKey.pageDown): const MonthIntent(1),

              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.pageUp): const YearIntent(-1),
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.pageDown): const YearIntent(1),

              LogicalKeySet(LogicalKeyboardKey.enter): const AcceptIntent(),
              LogicalKeySet(LogicalKeyboardKey.escape): const CancelIntent(),
            },
            child: Actions(
              actions: {
                DirectionIntent: CallbackAction<DirectionIntent>(
                  onInvoke: (intent) => _moveDays(intent.offset),
                ),
                MonthIntent: CallbackAction<MonthIntent>(
                  onInvoke: (intent) => _moveMonths(intent.offset),
                ),
                YearIntent: CallbackAction<YearIntent>(
                  onInvoke: (intent) => _moveYears(intent.offset),
                ),
                AcceptIntent: CallbackAction<AcceptIntent>(
                  onInvoke: (intent) => _accept(),
                ),
                CancelIntent: CallbackAction<CancelIntent>(
                  onInvoke: (intent) => Navigator.pop(context, null),
                ),
              },
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildInputArea(),
                            const SizedBox(height: 6),
                            _buildYearSelector(),
                            _buildHeader(fmtHeader),
                            const SizedBox(height: 4),
                            _buildCalendar(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: _buildButtons(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ------------------------------------------------------------
  /// INPUT AREA
  /// ------------------------------------------------------------
  Widget _buildInputArea() {
    if (widget.mode == ERPDatePickerMode.single) {
      return TextField(
        controller: ctrlSingle,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 6),
          border: OutlineInputBorder(),
        ),
        onChanged: (text) {
          final dt = _parse(text);
          if (dt != null) {
            setState(() {
              selected = dt;
              visibleMonth = DateTime(dt.year, dt.month);
            });
          }
        },
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrlFrom,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              labelText: "Desde",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              final dt = _parse(text);
              if (dt != null) {
                setState(() {
                  from = dt;
                  visibleMonth = DateTime(dt.year, dt.month);
                });
              }
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: ctrlTo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              labelText: "Hasta",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              final dt = _parse(text);
              if (dt != null) {
                setState(() {
                  to = dt;
                  visibleMonth = DateTime(dt.year, dt.month);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  /// ------------------------------------------------------------
  /// SELECTOR DE AÑO
  /// ------------------------------------------------------------
  Widget _buildYearSelector() {
    return DropdownButton<int>(
      value: visibleMonth.year,
      isDense: true,
      items: List.generate(80, (i) {
        final year = 1970 + i;
        return DropdownMenuItem(
          value: year,
          child: Text("$year", style: const TextStyle(fontSize: 12)),
        );
      }),
      onChanged: (year) {
        if (year != null) {
          setState(() {
            visibleMonth = DateTime(year, visibleMonth.month);
          });
        }
      },
    );
  }

  /// ------------------------------------------------------------
  /// HEADER MES
  /// ------------------------------------------------------------
  Widget _buildHeader(DateFormat fmtHeader) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          iconSize: 20,
          padding: EdgeInsets.zero,
          onPressed: _prevMonth,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          fmtHeader.format(visibleMonth),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        IconButton(
          iconSize: 20,
          padding: EdgeInsets.zero,
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  /// ------------------------------------------------------------
  /// CALENDARIO
  /// ------------------------------------------------------------
  Widget _buildCalendar() {
    return ERPMonthView(
      month: visibleMonth,
      selected: selected,
      rangeFrom: from,
      rangeTo: to,
      mode: widget.mode,
      onSelect: (day) {
        if (widget.mode == ERPDatePickerMode.single) {
          ctrlSingle.text = fmt.format(day);
          Navigator.pop(context, day);
        } else {
          _handleRangeSelection(day);
        }
      },
    );
  }

  void _handleRangeSelection(DateTime day) {
    setState(() {
      if (from == null || (from != null && to != null)) {
        from = day;
        to = null;
        ctrlFrom.text = fmt.format(day);
        ctrlTo.text = "";
      } else {
        if (day.isBefore(from!)) {
          to = from;
          from = day;
        } else {
          to = day;
        }
        ctrlFrom.text = fmt.format(from!);
        ctrlTo.text = fmt.format(to!);
      }
    });
  }

  /// ------------------------------------------------------------
  /// BOTONES
  /// ------------------------------------------------------------
  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            final now = DateTime.now();
            if (widget.mode == ERPDatePickerMode.single) {
              Navigator.pop(context, now);
            } else {
              Navigator.pop(context, (now, now));
            }
          },
          child: const Text("Hoy", style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: () {
            if (widget.mode == ERPDatePickerMode.single) {
              Navigator.pop(context, null);
            } else {
              Navigator.pop(context, (null, null));
            }
          },
          child: const Text("Limpiar", style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancelar", style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: _accept,
          child: const Text("Aceptar", style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// CALENDARIO (single + range) + HOVER
/// ------------------------------------------------------------

class ERPMonthView extends StatefulWidget {
  final DateTime month;
  final DateTime selected;

  final DateTime? rangeFrom;
  final DateTime? rangeTo;

  final ERPDatePickerMode mode;
  final ValueChanged<DateTime> onSelect;

  const ERPMonthView({
    super.key,
    required this.month,
    required this.selected,
    required this.mode,
    required this.onSelect,
    this.rangeFrom,
    this.rangeTo,
  });

  @override
  State<ERPMonthView> createState() => _ERPMonthViewState();
}

class _ERPMonthViewState extends State<ERPMonthView> {
  DateTime? hoverDay;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(widget.month.year, widget.month.month, 1);
    final firstWeekday = firstDay.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(widget.month.year, widget.month.month);

    const weekdays = ['D', 'L', 'K', 'M', 'J', 'V', 'S'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdays
              .map((d) => SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.2,
          ),
          itemCount: 42,
          itemBuilder: (context, index) {
            final day = index - firstWeekday + 1;
            final isValid = day >= 1 && day <= daysInMonth;
            final current = DateTime(widget.month.year, widget.month.month, day);

            if (!isValid) return const SizedBox();

            final isSelected = widget.mode == ERPDatePickerMode.single &&
                current.year == widget.selected.year &&
                current.month == widget.selected.month &&
                current.day == widget.selected.day;

            final isHover = hoverDay != null &&
                hoverDay!.year == current.year &&
                hoverDay!.month == current.month &&
                hoverDay!.day == current.day;

            return MouseRegion(
              onEnter: (_) => setState(() => hoverDay = current),
              onExit: (_) => setState(() => hoverDay = null),
              child: InkWell(
                onTap: () => widget.onSelect(current),
                child: Container(
                  decoration: isSelected
                      ? BoxDecoration(
                          color: Colors.blueGrey.shade700,
                          borderRadius: BorderRadius.circular(4),
                        )
                      : isHover
                          ? BoxDecoration(
                              color: Colors.blueGrey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                  child: Center(
                    child: Text(
                      "$day",
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}