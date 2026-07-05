import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../providers/checkout_provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/app_messages.dart';
import 'package:flutter/services.dart';

class StepAddressWidget extends StatefulWidget {
  const StepAddressWidget({super.key});

  @override
  State<StepAddressWidget> createState() => _StepAddressWidgetState();
}

class _StepAddressWidgetState extends State<StepAddressWidget> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckoutProvider>();

    return Column(
      children: [
        // Scrollable Form Content
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(16.w),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Billing Details"),
                SizedBox(height: 15.h),
                _buildLabelAndField(provider.billFirstNameController,
                    "First Name *", "Kamlesh"),
                _buildLabelAndField(
                    provider.billLastNameController, "Last Name *", "jangid"),
                _buildLabelAndField(
                    provider.billStreetController,
                    "Street Address *",
                    "Enter Your House number and street name"),
                _buildLabelAndField(provider.billStreet2Controller, "",
                    "Enter Your Apartment, suite, unit etc.."), // No label for 2nd line in screenshot usually? Or maybe hidden. Assuming screenshot shows blank label or just box. Actually 2nd box has hint. I'll pass empty label or manage spacing.
                // Screenshot shows "Street Address *" then two boxes.
                // Let's handle this: The first call handles the label. The second just the box.
                // But my helper does label + box.
                // Let's make label optional.

                _buildLabelAndField(provider.billCityController,
                    "Town / City *", "Enter Your Town / City"),
                _buildLabelAndField(provider.billStateController,
                    "State / Country *", "Enter Your State / Country"),
                _buildLabelAndField(provider.billPostCodeController,
                    "Postcode / ZIP *", "Enter Your Postcode / ZIP",
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                _buildLabelAndField(
                    provider.billPhoneController, "Phone *", "9012345678",
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                _buildLabelAndField(provider.billEmailController,
                    provider.isEmailRequired ? "Email Address * " : "Email Address", "Enter Your Email",
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: provider.isNewAddressChecked ? TextInputAction.next : TextInputAction.done),

                SizedBox(height: 10.h),
                Row(
                  children: [
                    Checkbox(
                      value: provider.isNewAddressChecked,
                      onChanged: (val) {
                        provider.toggleNewAddress(val ?? false);
                      },
                      activeColor: AppTheme.tealColor,
                    ),
                    Text(
                      "Ship to a different address?",
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor),
                    ),
                  ],
                ),

                if (provider.isNewAddressChecked) ...[
                  SizedBox(height: 15.h),
                  _buildSectionTitle("Shipping Details"),
                  SizedBox(height: 15.h),

                  // Saved Addresses Dropdown
                  if (provider.addressList.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(bottom: 15.h),
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          itemHeight: null,
                          value: provider.selectedAddressIndex,
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                child: Text("Choose Shipping Address *"),
                              ),
                            ),
                            ...List.generate(provider.addressList.length,
                                (index) {
                              final addr = provider.addressList[index];
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  child: Text(
                                    [
                                      "${addr.firstName ?? ''} ${addr.lastName ?? ''}",
                                      "${addr.street ?? ''} ${addr.street2 ?? ''}",
                                      "${addr.suburb ?? ''} ${addr.state ?? ''} ${addr.postcode ?? ''}"
                                    ]
                                        .map((s) => s.trim())
                                        .where((s) => s.isNotEmpty)
                                        .join(", "),
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              provider.onAddressSelected(val);
                            }
                          },
                        ),
                      ),
                    ),

                  _buildLabelAndField(provider.shipFirstNameController,
                      "First Name *", "First Name"),
                  _buildLabelAndField(provider.shipLastNameController,
                      "Last Name *", "Last Name"),
                  _buildLabelAndField(
                      provider.shipStreetController,
                      "Street Address *",
                      "Enter Your House number and street name"),
                  _buildLabelAndField(provider.shipStreet2Controller, "",
                      "Enter Your Apartment, suite, unit etc.."),
                  _buildLabelAndField(provider.shipCityController,
                      "Town / City *", "Enter Your Town / City"),
                  _buildLabelAndField(provider.shipStateController,
                      "State / Country *", "Enter Your State / Country"),
                  _buildLabelAndField(provider.shipPostCodeController,
                      "Postcode / ZIP *", "Enter Your Postcode / ZIP",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ]),
                  _buildLabelAndField(
                      provider.shipPhoneController, "Phone *", "Phone",
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                  _buildLabelAndField(provider.shipEmailController,
                      provider.isEmailRequired ? "Email Address * " : "Email Address", "Email Address",
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done),
                ],

                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
        ),

        // Sticky Bottom Navigation (Shadow + Buttons)
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back Button
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: SizedBox(
                    height: 45.h,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.previousStep();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkGrayColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios, color: Colors.white, size: 16.sp),
                          SizedBox(width: 5.w),
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text("Back",
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Dynamic Step Indicator
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("${provider.currentStep + 1}/${provider.totalSteps}",
                        maxLines: 1,
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              // Next Button
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: SizedBox(
                    height: 45.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (provider.validateAddressStep()) {
                          provider.nextStep();
                        } else {
                          Fluttertoast.showToast(msg: AppMessages.pleaseFillAllRequiredFields);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.companyId == "2" ? AppTheme.primaryColor : AppTheme.primaryButtonColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(left: 8.w),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text("Next",
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16.sp),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor, // Blue color from screenshot
      ),
    );
  }

  Widget _buildLabelAndField(
      TextEditingController controller, String label, String hint,
      {TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters,
      TextInputAction textInputAction = TextInputAction.next}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor, // Blueish Label
              ),
            ),
            SizedBox(height: 8.h),
          ],
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            style: TextStyle(fontSize: 14.sp, color: AppTheme.textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: AppTheme.hintColor, fontSize: 13.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide:
                    BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
