import "package:al_quran_v3/src/theme/values/values.dart";
import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../../theme/controller/theme_cubit.dart";
import "../../theme/controller/theme_state.dart";

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  static List<FlexScheme> appSchemes = [
    FlexScheme.tealM3,
    FlexScheme.blue,
    FlexScheme.deepPurple,
    FlexScheme.orangeM3,
    FlexScheme.blueWhale,
    FlexScheme.mandyRed,
    FlexScheme.red,
    FlexScheme.indigo,
    FlexScheme.espresso,
    FlexScheme.sakura,
    FlexScheme.amber,
    FlexScheme.cyanM3,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(appSchemes.length, (index) {
              FlexScheme currentScheme = appSchemes[index];
              Color currentPrimaryColor = FlexColor.schemes[currentScheme]!.light.primary;
              bool isSelected = themeState.flexScheme == currentScheme;
              return Padding(
                padding: const EdgeInsets.all(5),
                child: InkWell(
                  onTap: () {
                    context.read<ThemeCubit>().changeFlexScheme(currentScheme);
                  },
                  child: Container(
                    height: 40,
                    width: 60,
                    decoration: BoxDecoration(
                      color: currentPrimaryColor,
                      borderRadius: BorderRadius.circular(roundedRadius),
                    ),
                    child:
                        isSelected
                            ? const Icon(Icons.done, color: Colors.white)
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

