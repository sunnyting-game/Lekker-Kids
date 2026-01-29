import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_strings.dart';
import '../../../constants/app_theme.dart';
import '../../../models/weekly_plan.dart';
import '../../../viewmodels/weekly_plan_view_model.dart';

import 'weekly_plan/widgets/add_plan_dialog.dart';
import 'weekly_plan/widgets/day_column.dart';

class WeeklyPlanTab extends StatelessWidget {
  const WeeklyPlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeeklyPlanViewModel(),
      child: const _WeeklyPlanScreen(),
    );
  }
}

class _WeeklyPlanScreen extends StatelessWidget {
  const _WeeklyPlanScreen();

  void _showAddPlanDialog(BuildContext context) {
    final viewModel = context.read<WeeklyPlanViewModel>();
    showDialog(
      context: context,
      builder: (context) => AddPlanDialog(
        weekDays: viewModel.weekDays,
        year: viewModel.currentYear,
        weekNumber: viewModel.currentWeekNumber,
        weekDates: viewModel.weekDates,
        onSave: viewModel.addWeeklyPlan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: const [
          _WeeklyPlanHeader(),
          Expanded(
            child: _WeeklyPlanList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlanDialog(context),
        backgroundColor: AppColors.primary,
        child: Icon(
          Icons.add,
          color: AppColors.textWhite,
        ),
      ),
    );
  }
}

class _WeeklyPlanHeader extends StatelessWidget {
  const _WeeklyPlanHeader();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeeklyPlanViewModel>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: viewModel.goToPreviousWeek,
            tooltip: AppStrings.weeklyPlanPreviousWeek,
            color: AppColors.primary,
          ),
          Text(
            AppStrings.format(
              AppStrings.weeklyPlanWeekFormat,
              [viewModel.currentWeekNumber.toString(), viewModel.currentYear.toString()],
            ),
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: viewModel.goToNextWeek,
            tooltip: AppStrings.weeklyPlanNextWeek,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _WeeklyPlanList extends StatelessWidget {
  const _WeeklyPlanList();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeeklyPlanViewModel>();

    return StreamBuilder<Map<String, List<WeeklyPlan>>>(
      stream: viewModel.getWeeklyPlansStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: AppTextStyles.error,
            ),
          );
        }

        final plansByDay = snapshot.data ?? {};

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: viewModel.weekDays.map((day) {
              final plans = plansByDay[day] ?? [];
              final date = viewModel.weekDates[day]!;
              return DayColumn(
                day: day,
                date: date,
                plans: plans,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
