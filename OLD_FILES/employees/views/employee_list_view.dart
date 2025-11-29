import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import '../models/employee_list_model.dart';
import '../viewmodels/employee_list_view_model.dart';
import 'package:pluto_grid/pluto_grid.dart';

class EmployeeListView extends StatefulWidget {
  const EmployeeListView({super.key});

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
  late final EmployeeListViewModel _viewModel;
  late final List<PlutoColumn> _columns;

  @override
  void initState() {
    super.initState();
    _viewModel = EmployeeListViewModel(
      employeeRepository: locator<EmployeeRepository>(),
    );
    _columns = _buildColumns();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  List<PlutoColumn> _buildColumns() {
    return [
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.text(),
        hide: true,
      ),
      PlutoColumn(
        title: 'Сотрудник',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 250,
        renderer: (rendererContext) {
          final avatarUrl =
              rendererContext.row.cells['avatar']?.value as String?;
          final name = rendererContext.cell.value as String;
          final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
          return Row(
            children: [
              CircleAvatar(
                radius: 16,
                foregroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                child: Text(name[0]),
              ),
              const SizedBox(width: 12),
              Text(name),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'Должность',
        field: 'role',
        type: PlutoColumnType.text(),
        width: 150,
      ),
      PlutoColumn(
        title: 'Филиал',
        field: 'branch',
        type: PlutoColumnType.text(),
        width: 150,
      ),
      PlutoColumn(
        title: 'Статус',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 120,
        renderer: (rendererContext) {
          final status = rendererContext.cell.value as EmployeeStatus;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: status.color),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                color: status.color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Часы',
        field: 'hours',
        type: PlutoColumnType.number(),
        width: 100,
        formatter: (value) => '$value ч',
      ),
      PlutoColumn(
        title: 'Действия',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 100,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (rendererContext) {
          return IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () {
              final id = rendererContext.row.cells['id']?.value as String;
              locator<RouterService>().goTo(
                Path(name: '/dashboard/employees/$id'),
              );
            },
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Поиск сотрудника...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _viewModel.setSearchQuery,
                ),
              ),
              const SizedBox(width: 16),
              // TODO: Add filters here
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<AsyncValue<List<EmployeeListModel>>>(
            valueListenable: _viewModel.state,
            builder: (context, state, child) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.hasError) {
                return Center(child: Text('Ошибка: ${state.errorOrNull}'));
              }

              final employees = state.dataOrNull ?? [];

              return PlutoGrid(
                columns: _columns,
                rows: _viewModel.getPlutoRows(employees),
                configuration: const PlutoGridConfiguration(
                  style: PlutoGridStyleConfig(
                    rowHeight: 60,
                    gridBorderColor: Colors.transparent,
                    activatedColor: Color(0xFFF5F7FA),
                    cellTextStyle: TextStyle(fontSize: 14),
                    columnTextStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                createFooter: (stateManager) {
                  stateManager.setPageSize(20, notify: false);
                  return PlutoPagination(stateManager);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
