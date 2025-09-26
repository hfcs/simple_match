import 'package:flutter/material.dart';
import '../viewmodel/stage_result_viewmodel.dart';

class StageResultView extends StatelessWidget {
	final StageResultViewModel viewModel;
	const StageResultView({super.key, required this.viewModel});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Stage Result')),
			body: const Center(child: Text('Stage Result View Placeholder')),
		);
	}
}
