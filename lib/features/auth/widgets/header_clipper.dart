import 'package:flutter/material.dart';

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height); // Garis ke kiri bawah
    
    // Titik kontrol di tengah bawah, membuat lengkungan cekung (ke atas)
    var controlPoint = Offset(size.width / 2, size.height - 35);
    var endPoint = Offset(size.width, size.height);
    
    path.quadraticBezierTo(
      controlPoint.dx, 
      controlPoint.dy, 
      endPoint.dx, 
      endPoint.dy,
    );
    
    path.lineTo(size.width, 0); // Naik ke kanan atas
    path.close(); // Tutup path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}