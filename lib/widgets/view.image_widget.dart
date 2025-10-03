import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hanap_raket/utils/colors.dart';

class ViewImageWidget extends StatelessWidget {
  String image;

  ViewImageWidget({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cloudWhite,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: cloudWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            FontAwesomeIcons.arrowLeftLong,
            color: primary,
          ),
        ),
      ),
      body: Center(
        child: Image.network(
          image,
        ),
      ),
    );
  }
}
