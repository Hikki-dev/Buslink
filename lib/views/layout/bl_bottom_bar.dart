import 'package:flutter/material.dart';
import '../../utils/bl_colors.dart';

/// The phone's bottom bar (mockup "Main"): 80 px high, big labels, and a
/// blush pill behind the icon of the page you are on.
class BlBottomBar extends StatelessWidget {
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BlBottomBar(
      {super.key,
      required this.items,
      required this.currentIndex,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: BL.hairline))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _Item(
                      item: items[i],
                      selected: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final BottomNavigationBarItem item;
  final bool selected;
  final VoidCallback onTap;
  const _Item(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? BL.crimson : BL.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        key: item.key,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? BL.blush : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconTheme(
                data: IconThemeData(color: color, size: 22),
                child: selected ? item.activeIcon : item.icon,
              ),
            ),
            const SizedBox(height: 4),
            Text(item.label ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
