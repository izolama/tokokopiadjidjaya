import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'admin_order_list.dart';
import 'admin_order_summary.dart';
import 'admin_product_form.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Order summary'),
              subtitle: const Text('Daily, weekly, monthly recap'),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const AdminOrderSummaryPage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.coffee),
              title: const Text('Product management'),
              subtitle: const Text('Create, edit, or deactivate coffee items'),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const AdminProductManagementPage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Order verification'),
              subtitle: const Text('Review orders and update status'),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const AdminOrderListPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
