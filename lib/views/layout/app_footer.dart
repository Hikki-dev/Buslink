import 'package:flutter/material.dart';
import '../../utils/bl_colors.dart';

/// Dark red footer used under the desktop pages. The photo credits are
/// required by the licences of the pictures on the home screen.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const credits =
      'Photos from Wikimedia Commons: Nine Arches Bridge by A.Savin (FAL); '
      'Temple of the Tooth by Vyacheslav Argenberg (CC BY 4.0); '
      'Galle Fort by calflier001 (CC BY-SA 2.0); '
      'tea hills by Bergentroll (CC0); '
      'Sigiriya by Prasanna tharaka (CC BY-SA 4.0).';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: BL.crimsonDark,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BusLink',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text(credits,
                    style:
                        TextStyle(color: BL.blush, fontSize: 14, height: 1.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A page body that scrolls, with the footer at the bottom of the window when
/// the page is short and at the end of the page when it is long.
class FooterScroll extends StatelessWidget {
  final List<Widget> children;
  const FooterScroll({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(children: children),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
