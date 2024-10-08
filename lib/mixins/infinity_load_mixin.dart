import 'package:flutter/material.dart';

abstract class FetchProvider {
  void onInfinityFetch();
}

mixin InfiniteScrollMixin<T extends StatefulWidget> on State<T> implements FetchProvider {
  ScrollController infinityScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    infinityScrollController.addListener(_onHandleScroll);
  }

  @override
  void dispose() {
    infinityScrollController.dispose();
    super.dispose();
  }

  void _onHandleScroll() {
    if (infinityScrollController.hasClients) {
      final maxScroll = infinityScrollController.position.maxScrollExtent;
      final currentScroll = infinityScrollController.offset;
      if (currentScroll >= (maxScroll * 0.95)) {
        onInfinityFetch();
      }
    }
  }
}
