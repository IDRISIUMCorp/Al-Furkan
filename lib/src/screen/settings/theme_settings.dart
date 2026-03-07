import "package:flutter/material.dart";
import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../../theme/controller/theme_cubit.dart";
import "../../theme/controller/theme_state.dart";

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  static List<FlexScheme> appSchemes = [
    FlexScheme.tealM3,
    FlexScheme.blueM3,
    FlexScheme.deepPurple,
    FlexScheme.indigoM3,
    FlexScheme.sakura,
    FlexScheme.mandyRed,
    FlexScheme.gold,
    FlexScheme.brandBlue,
    FlexScheme.ebonyClay,
    FlexScheme.redWine,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(appSchemes.length, (index) {
              final FlexScheme scheme = appSchemes[index];
              final Color primaryColor = FlexColor.schemes[scheme]!.light.primary;
              final bool isSelected = themeState.flexScheme == scheme;

              return Padding(
                padding: const EdgeInsets.all(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    context.read<ThemeCubit>().changeFlexScheme(scheme);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    height: isSelected ? 50 : 40,
                    width: isSelected ? 50 : 40,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(isSelected ? 16 : 12),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ] : [],
                      border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                        : null,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

