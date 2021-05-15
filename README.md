# Fancy Switcher

Wrapper for `animations` package to abstract away transitions and just use the widget as an animated switcher.

## Switching Image

Includes a switcher for image providers, to support gapless decoding & gapless switching, idle children and animated gifs.

## Examples

Check [Flutter Firestore](https://github.com/volskaya/flutter_firestore) for real usage.

###### Animated switcher using the material design vertical animation

```dart
Widget list;
switch (listStatus) {
  case ListStatus.loading:
    list = KeyedSubtree(
      key: ObjectKey(listStatus),
      child: CircularProgressIndicator(),
    );
    break;
  case ListStatus.empty:
    list = KeyedSubtree(
      key: ObjectKey(listStatus),
      child: Text('Nothing here'),
    );
    break;
  case ListStatus.paginated:
    list = KeyedSubtree(
      key: ObjectKey(listStatus),
      child: ListView(...),
    );
    break;
}

return FancySwitcher.vertical(
  child: list,
);
```

###### Animated switching of an image

```dart
return SwitchingImage(
  imageProvider: NetworkImage(...),
  idleChild: CircularProgressIndicator(),
);
```
