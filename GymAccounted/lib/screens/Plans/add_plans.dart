import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Modal/plan_dm.dart';
import 'package:gymaccounted/Networking/plans_api.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;

class AddPlans extends StatefulWidget {
  final Plan? plan; // Accept Plan object

  const AddPlans({Key? key, this.plan}) : super(key: key);

  @override
  _AddPlansState createState() => _AddPlansState();
}

class _AddPlansState extends State<AddPlans> {
  final TextEditingController _planNameController = TextEditingController();
  final TextEditingController _planPriceController = TextEditingController();
  late PlanService _planService;
  int? _selectedPlanLimit;

  @override
  void initState() {
    super.initState();
    _planService = PlanService(Supabase.instance.client);

    // Initialize fields if plan data is provided
    if (widget.plan != null) {
      final plan = widget.plan!;
      _planNameController.text = plan.planName;
      _selectedPlanLimit = plan.planLimit;
      _planPriceController.text = plan.planPrice.toString();
    }
  }

  Future<void> _submit() async {
    if (_planNameController.text.isEmpty ||
        _selectedPlanLimit == null ||
        _planPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    gymUser.User? user = await gymUser.User.getUser();
    String? gymId = user?.id ?? "";
    final plan = Plan(
      id: widget.plan?.id ?? 0,
      planName: _planNameController.text,
      planLimit: _selectedPlanLimit!,
      planPrice: _planPriceController.text,
      gymId: gymId,
    );

    try {
      if (widget.plan == null) {
        await _planService.insertPlan(
          name: _planNameController.text,
          price: _planPriceController.text,
          limit: _selectedPlanLimit!,
          gymId: gymId,
        );
      } else {
        await _planService.updatePlan(plan.id, plan);
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan saved successfully.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plan == null ? 'Add Plan' : 'Edit Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _planNameController,
                decoration: InputDecoration(
                  labelText: 'Plan Name',
                  prefixIcon: Icon(Icons.event),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedPlanLimit,
                items: [1, 3, 6, 12]
                    .map((limit) => DropdownMenuItem<int>(
                  value: limit,
                  child: Text('$limit Month',style: TextStyle(fontWeight: FontWeight.bold)),
                ))
                    .toList(),
                decoration: InputDecoration(
                  labelText: 'Plan Limit',
                  prefixIcon: Icon(Icons.event),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedPlanLimit = value;
                  });
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: _planPriceController,
                decoration: InputDecoration(
                  labelText: 'Plan Price',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
