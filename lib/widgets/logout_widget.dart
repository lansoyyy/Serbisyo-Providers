// import 'package:customer_loyalty/screens/auth/login_screen.dart';
// import 'package:customer_loyalty/utils/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:quickalert/quickalert.dart';

// void logout(BuildContext context, Widget navigationRoute) {
//   QuickAlert.show(
//     context: context,
//     type: QuickAlertType.warning,
//     title: 'Logout Confirmation',
//     text: 'Are you sure you want to logout?',
//     titleColor: const Color(0xFF1C2526),
//     textColor: const Color(0xFF1C2526),
//     confirmBtnText: 'Continue',
//     confirmBtnColor: bayanihanBlue,
//     cancelBtnText: 'Close',
//     showCancelBtn: true,
//     confirmBtnTextStyle: const TextStyle(
//       fontFamily: 'Regular',
//       fontWeight: FontWeight.bold,
//       color: Colors.white,
//     ),
//     cancelBtnTextStyle: const TextStyle(
//       fontFamily: 'Regular',
//       fontWeight: FontWeight.bold,
//       color: Color(0xFF1C2526),
//     ),
//     onConfirmBtnTap: () async {
//       final box = GetStorage();
//       await box.erase();
//       Get.offAll(() => MerchantLoginScreen(),
//           transition: Transition.circularReveal);
//     },
//     onCancelBtnTap: () {
//       Navigator.of(context).pop();
//     },
//   );
// }
