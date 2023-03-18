import 'package:flutter/material.dart';

class NavigationRow extends StatelessWidget {

  VoidCallback decrementWeekCounter;
  VoidCallback incrementWeekCounter;

  NavigationRow(this.decrementWeekCounter, this.incrementWeekCounter);

 // Create the constructor that tekes in the methods that will be passed in from drowsinessGrage

  @override
  Widget build(BuildContext context) {

  return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: decrementWeekCounter,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: incrementWeekCounter,
          ),
        ],
      );
  }
}