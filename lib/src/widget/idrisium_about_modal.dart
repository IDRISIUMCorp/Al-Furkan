import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class IdrisiumAboutModal extends StatelessWidget {
  const IdrisiumAboutModal({super.key});

  static Future<void> show(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IdrisiumAboutModal(),
    );
  }

  Future<void> _launch(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0EA47A);
    const accentDim = Color(0xFF0A7D5C);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 34),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF080808),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          border: Border(
            top: BorderSide(color: accent.withValues(alpha: 0.15)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 28),

            // Avatar with glow ring
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [accent, Color(0xFF06D6A0), accentDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F0F0F),
                  border: Border.all(color: const Color(0xFF0F0F0F), width: 3),
                ),
                child: ClipOval(
                  child: Image.asset(
                    "assets/dev/dev image.jpg",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text(
                        "إ",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Brand name
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFF06D6A0)],
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: const Text(
                "IDRISIUM",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "إدريس غامد",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: const Text(
                "مطوّر تطبيقات · مصمّم",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Social links card
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  _SocialTile(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF06D6A0),
                    title: "Website",
                    subtitle: "idrisium.linkpc.net",
                    onTap: () => _launch("http://idrisium.linkpc.net/"),
                  ),
                  _SocialDivider(),
                  _SocialTile(
                    icon: Icons.camera_alt_rounded,
                    iconColor: const Color(0xFFE1306C),
                    title: "Instagram / TikTok",
                    subtitle: "@idris.ghamid",
                    onTap: () => _launch("https://instagram.com/idris.ghamid"),
                  ),
                  _SocialDivider(),
                  _SocialTile(
                    icon: Icons.send_rounded,
                    iconColor: const Color(0xFF0088CC),
                    title: "Telegram",
                    subtitle: "@IDRV72",
                    onTap: () => _launch("https://t.me/IDRV72"),
                  ),
                  _SocialDivider(),
                  _SocialTile(
                    icon: Icons.code_rounded,
                    iconColor: Colors.white,
                    title: "GitHub",
                    subtitle: "github.com/IDRISIUM",
                    onTap: () => _launch("https://github.com/IDRISIUM"),
                  ),
                  _SocialDivider(),
                  _SocialTile(
                    icon: Icons.email_outlined,
                    iconColor: const Color(0xFFFF6B6B),
                    title: "Email",
                    subtitle: "idris.ghamid@gmail.com",
                    onTap: () => _launch("mailto:idris.ghamid@gmail.com"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Footer
            Text(
              "صُنع بـ ❤️ في مصر",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "© ${DateTime.now().year} IDRISIUM Corp. All rights reserved.",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.15),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SocialTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.12),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.04),
    );
  }
}
