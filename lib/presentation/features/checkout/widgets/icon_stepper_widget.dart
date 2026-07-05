import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_theme.dart';

class IconStepperWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Function(int) onStepTapped;

  const IconStepperWidget({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppTheme.stepperBG,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isEven) {
            // Step Icon
            int stepIndex = index ~/ 2;
            return _buildStepIcon(stepIndex);
          } else {
            // Connector Line
            int stepIndex = (index - 1) ~/ 2;
            return Expanded(child: _buildConnector(stepIndex));
          }
        }),
      ),
    );
  }

  Widget _buildStepIcon(int stepIndex) {
    bool isActive = currentStep == stepIndex;
    bool isCompleted = currentStep > stepIndex;

    // Icons matching Android: Cart, Shipping(Address), Payment, Preview
    // Assets matching Android: orcarticon, shippingicon, paymenticon, previewicon
    String assetPath;

    switch (stepIndex) {
      case 0:
        assetPath = "assets/images/orcarticon.png";
        break;
      case 1:
        assetPath = "assets/images/shippingicon.png";
        break;
      case 2:
        assetPath = "assets/images/paymenticon.png";
        break;
      case 3:
        assetPath = "assets/images/previewicon.png";
        break;
      default:
        assetPath = "";
    }

    Color bgColor;
    BoxBorder? border;
    Color iconColor;

    if (isCompleted) {
      // Completed: Filled Theme Color, Contrast Icon (White or Black)
      bgColor = AppTheme.tealColor;
      border = Border.all(color: AppTheme.tealColor, width: 2.w);
      iconColor = bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    } else if (isActive) {
      // Active: White Bg, Theme Color Border, Theme Color Icon
      bgColor = Colors.white;
      border = Border.all(color: AppTheme.tealColor, width: 2.w);
      iconColor = AppTheme.tealColor;
    } else {
      // Inactive: White Bg, Grey Border, Grey Icon
      bgColor = Colors.white;
      border = Border.all(color: AppTheme.borderColor, width: 1.5.w);
      iconColor = AppTheme.darkGrayColor;
    }

    return InkWell(
      onTap: () {
        // onStepTapped(stepIndex);
      },
      child: Container(
        width: 25.w,
        height: 25.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: border,
        ),
        padding: EdgeInsets.all(3.w),
        child: Image.asset(
          assetPath,
          color: iconColor,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildConnector(int stepIndex) {
    bool isCompleted = currentStep > stepIndex;
    return Container(
      height: 2.h,
      color: isCompleted ? AppTheme.tealColor : AppTheme.lightGrayBg,
    );
  }
}
