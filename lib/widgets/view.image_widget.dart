import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hanap_raket/utils/colors.dart';
import 'dart:io';

class ViewImageWidget extends StatelessWidget {
  String image;

  ViewImageWidget({required this.image});

  @override
  Widget build(BuildContext context) {
    // Check if it's a local file path or a URL
    final isUrl = image.startsWith('http');

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
        child: isUrl
            ? Image.network(
                image,
              )
            : Image.file(
                File(image),
              ),
      ),
    );
  }
}
