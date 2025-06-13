import 'package:flutter/material.dart';
import 'package:flutter_firebase_iot/pages/add_unit_page.dart';
import '../utils/theme.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Welcome, Admin',
              style: TextStyle(
                color: AppColors.navyBlue,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            // Navigation Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildNavCard(
                    context,
                    title: "Unit Details",
                    icon: Icons.home_work,
                    onTap: () => Navigator.pushNamed(context, '/unit-details'),
                  ),
                  _buildNavCard(
                    context,
                    title: "Income Analysis",
                    icon: Icons.analytics,
                    onTap: () => Navigator.pushNamed(context, '/debug'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddUnitPage()),
            ),
        backgroundColor: AppColors.navyBlue,
        child: Icon(Icons.add, color: AppColors.cream),
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: AppColors.cream),
              SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
