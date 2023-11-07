import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

@immutable
class Film {
  final String id;
  final String title;
  final String description;
  final bool isFavorite;

  const Film(
      {required this.id,
      required this.title,
      required this.description,
      required this.isFavorite});

  Film copy({required bool isFavorite}) => Film(
      id: id, title: title, description: description, isFavorite: isFavorite);

  @override
  String toString() =>
      'Film(id: $id, title: $title, description: $description, isFavorite: $isFavorite)';

  @override
  bool operator ==(covariant Film other) =>
      id == other.id && isFavorite == other.isFavorite;

  @override
  int get hashCode => Object.hashAll([id, isFavorite]);
}

const allFilms = [
  Film(
    id: '1',
    title: 'The Shawshank Redemption',
    description: 'Description for The Shawshark Redemption',
    isFavorite: false,
  ),
  Film(
    id: '2',
    title: 'The Godfather',
    description: 'Description for The Godfather',
    isFavorite: false,
  ),
  Film(
    id: '3',
    title: 'The Godfather: Part II',
    description: 'Description for The Godfather: Part II',
    isFavorite: false,
  ),
  Film(
    id: '4',
    title: 'The Dark Knight',
    description: 'Description for The Dark Knight',
    isFavorite: false,
  ),
];

class FilmsNotifier extends StateNotifier<List<Film>> {
  FilmsNotifier() : super(allFilms);

  void update(Film film, bool isFavorite) {
    state = state
        .map(
          (thisFilm) => thisFilm.id == film.id
              ? thisFilm.copy(isFavorite: isFavorite)
              : thisFilm,
        )
        .toList();
  }
}

enum FavoriteStatus { all, favorite, notFavorite }

// favorite status
final favoriteStatusProvider =
    StateProvider<FavoriteStatus>((_) => FavoriteStatus.all);

final allFilmsProvider =
    StateNotifierProvider<FilmsNotifier, List<Film>>((_) => FilmsNotifier());

final favoriteFilmsProvider = Provider<Iterable<Film>>(
  (ref) => ref.watch(allFilmsProvider).where((film) => film.isFavorite),
);

final notFavoriteFilmsProvider = Provider<Iterable<Film>>(
  (ref) => ref.watch(allFilmsProvider).where((film) => !film.isFavorite),
);

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        home: const HomePage());
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Home Page'),
      ),
      body: Column(
        children: [
          const FilterWidget(),
          Consumer(builder: (context, ref, child) {
            final filter = ref.watch(favoriteStatusProvider);
            switch (filter) {
              case FavoriteStatus.all:
                return FilmsList(provider: allFilmsProvider);
              case FavoriteStatus.favorite:
                return FilmsList(provider: favoriteFilmsProvider);
              case FavoriteStatus.notFavorite:
                return FilmsList(provider: notFavoriteFilmsProvider);
            }
          })
        ],
      ),
    );
  }
}

class FilmsList extends ConsumerWidget {
  final AlwaysAliveProviderBase<Iterable<Film>> provider;
  const FilmsList({required this.provider, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final films = ref.watch(provider);
    return Expanded(
        child: ListView.builder(
      itemCount: films.length,
      itemBuilder: (context, index) {
        final film = films.elementAt(index);
        final favoriteIcon = film.isFavorite
            ? const Icon(Icons.favorite)
            : const Icon(Icons.favorite_border);

        return ListTile(
          title: Text(film.title),
          subtitle: Text(film.description),
          trailing: IconButton(
            icon: favoriteIcon,
            onPressed: () {
              final isFavorite = !film.isFavorite;
              ref.read(allFilmsProvider.notifier).update(film, isFavorite);
            },
          ),
        );
      },
    ));
  }
}

class FilterWidget extends StatelessWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return DropdownButton(
          value: ref.watch(favoriteStatusProvider),
          items: FavoriteStatus.values
              .map((fs) => DropdownMenuItem(
                    value: fs,
                    child: Text(
                      fs.toString().split('.').last,
                    ),
                  ))
              .toList(),
          onChanged: (fs) {
            ref.read(favoriteStatusProvider.state).state = fs!;
          },
        );
      },
    );
  }
}
