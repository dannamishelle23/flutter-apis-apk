import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(PokemonApp());
}

class PokemonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon API',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PokemonList(),
    );
  }
}

class PokemonList extends StatefulWidget {
  @override
  _PokemonListState createState() => _PokemonListState();
}

class _PokemonListState extends State<PokemonList> {
  List<Map<String, dynamic>> _pokemonList = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPokemon();
  }

  Future<void> fetchPokemon({String? searchTerm}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> pokemonWithImages = [];
      
      if (searchTerm != null && searchTerm.isNotEmpty) {
        // Buscar Pokémon específico
        final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/${searchTerm.toLowerCase()}');
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final detailsData = json.decode(response.body);
          pokemonWithImages.add({
            'name': detailsData['name'],
            'image': detailsData['sprites']['front_default'],
            'id': detailsData['id'],
          });
        } else {
          throw Exception('Pokémon no encontrado');
        }
      } else {
        // Cargar lista de Pokémon
        final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50');
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List results = data['results'];

          for (var pokemon in results) {
            final detailsResponse = await http.get(Uri.parse(pokemon['url']));
            if (detailsResponse.statusCode == 200) {
              final detailsData = json.decode(detailsResponse.body);
              pokemonWithImages.add({
                'name': pokemon['name'],
                'image': detailsData['sprites']['front_default'],
                'id': detailsData['id'],
              });
            }
          }
        } else {
          throw Exception('Error al cargar los Pokémon.');
        }
      }

      setState(() {
        _pokemonList = pokemonWithImages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }

  void _searchPokemon() {
    if (_searchController.text.isNotEmpty) {
      fetchPokemon(searchTerm: _searchController.text);
    } else {
      fetchPokemon();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokémon API'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar Pokémon (ej: ditto)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchPokemon,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _pokemonList.length,
                    itemBuilder: (context, index) {
                      final pokemon = _pokemonList[index];
                      return ListTile(
                        leading: pokemon['image'] != null
                            ? Image.network(pokemon['image'])
                            : Icon(Icons.image_not_supported),
                        title: Text(pokemon['name']),
                        subtitle: Text('ID: ${pokemon['id']}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PokemonDetail(pokemonName: pokemon['name']),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// NUEVA CLASE PARA MOSTRAR DETALLES DEL POKÉMON
class PokemonDetail extends StatefulWidget {
  final String pokemonName;

  PokemonDetail({required this.pokemonName});

  @override
  _PokemonDetailState createState() => _PokemonDetailState();
}

class _PokemonDetailState extends State<PokemonDetail> {
  Map<String, dynamic>? _pokemonDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPokemonDetails();
  }

  Future<void> fetchPokemonDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/${widget.pokemonName}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pokemonDetails = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar los detalles del Pokémon');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }

  Widget _buildStat(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text('$value'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pokemonDetails?['name']?.toString().toUpperCase() ?? 'Cargando...'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: _pokemonDetails?['sprites']?['front_default'] != null
                        ? Image.network(
                            _pokemonDetails!['sprites']['front_default'],
                            height: 200,
                            width: 200,
                          )
                        : Icon(Icons.image_not_supported, size: 200),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'ID: ${_pokemonDetails?['id']}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Altura: ${(_pokemonDetails?['height'] ?? 0) / 10} m',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Peso: ${(_pokemonDetails?['weight'] ?? 0) / 10} kg',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Estadísticas:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_pokemonDetails?['stats'] != null)
                    ..._pokemonDetails!['stats'].map<Widget>((stat) {
                      return _buildStat(
                        stat['stat']['name'].toString().toUpperCase(),
                        stat['base_stat'],
                      );
                    }).toList(),
                  SizedBox(height: 20),
                  Text(
                    'Habilidades:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_pokemonDetails?['abilities'] != null)
                    ..._pokemonDetails!['abilities'].map<Widget>((ability) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '• ${ability['ability']['name']}',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                  SizedBox(height: 20),
                  Text(
                    'Tipos:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_pokemonDetails?['types'] != null)
                    Wrap(
                      spacing: 8.0,
                      children: _pokemonDetails!['types'].map<Widget>((type) {
                        return Chip(
                          label: Text(type['type']['name'].toString().toUpperCase()),
                          backgroundColor: Colors.blue[100],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }
}