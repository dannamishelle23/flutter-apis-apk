import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CatAPIApp extends StatelessWidget {
  const CatAPIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat API - Actividad 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const CatBreedsScreen(),
    );
  }
}

class CatBreedsScreen extends StatefulWidget {
  const CatBreedsScreen({super.key});

  @override
  State<CatBreedsScreen> createState() => _CatBreedsScreenState();
}

class _CatBreedsScreenState extends State<CatBreedsScreen> {
  List<Map<String, dynamic>> _catBreeds = [];
  List<Map<String, dynamic>> _allBreeds = []; // Para mantener la lista completa
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _useAlternativeApi = false;

  @override
  void initState() {
    super.initState();
    fetchCatBreeds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getPlaceholderImage(String breedName) {
    final breedLower = breedName.toLowerCase();
    
    if (breedLower.contains('siamese')) {
      return 'https://cdn.pixabay.com/photo/2018/01/28/12/37/cat-3113513_640.jpg';
    } else if (breedLower.contains('persian') || breedLower.contains('persa')) {
      return 'https://cdn.pixabay.com/photo/2017/11/09/21/41/cat-2934720_640.jpg';
    } else if (breedLower.contains('maine')) {
      return 'https://cdn.pixabay.com/photo/2018/07/13/10/20/cat-3535404_640.jpg';
    } else if (breedLower.contains('sphynx')) {
      return 'https://cdn.pixabay.com/photo/2018/01/28/12/37/cat-3113513_640.jpg';
    } else if (breedLower.contains('bengal')) {
      return 'https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_640.jpg';
    } else if (breedLower.contains('ragdoll')) {
      return 'https://cdn.pixabay.com/photo/2015/11/16/14/43/cat-1045782_640.jpg';
    } else {
      final genericImages = [
        'https://cdn.pixabay.com/photo/2014/11/30/14/11/cat-551554_640.jpg',
        'https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_640.jpg',
        'https://cdn.pixabay.com/photo/2015/11/16/14/43/cat-1045782_640.jpg',
        'https://cdn.pixabay.com/photo/2018/07/13/10/20/cat-3535404_640.jpg',
        'https://cdn.pixabay.com/photo/2017/11/14/13/06/kitty-2948404_640.jpg',
      ];
      return genericImages[breedName.hashCode.abs() % genericImages.length];
    }
  }

  Future<void> fetchCatBreeds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_useAlternativeApi) {
        await _fetchFromAlternativeAPI();
      } else {
        await _fetchFromTheCatAPI();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _fetchFromTheCatAPI() async {
    final apiKey = dotenv.env['CAT_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key no configurada. Verifica tu archivo .env');
    }

    final response = await http.get(
      Uri.parse('https://api.thecatapi.com/v1/breeds'),
      headers: {'x-api-key': apiKey},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> breeds = [];
      for (var breed in data) {
        String imageUrl = _getPlaceholderImage(breed['name'] ?? 'Cat');
        
        final imageId = breed['reference_image_id'];
        if (imageId != null) {
          imageUrl = 'https://cdn2.thecatapi.com/images/$imageId.jpg';
        }
        
        breeds.add({
          'id': breed['id'] ?? '',
          'name': breed['name'] ?? 'Sin nombre',
          'description': breed['description'] ?? 'Sin descripción disponible',
          'origin': breed['origin'] ?? 'Origen desconocido',
          'life_span': breed['life_span'] ?? 'No especificado',
          'temperament': breed['temperament'] ?? 'No especificado',
          'weight': breed['weight'] != null 
              ? '${breed['weight']['metric']} kg' 
              : 'No especificado',
          'intelligence': breed['intelligence'] ?? 5,
          'affection_level': breed['affection_level'] ?? 5,
          'energy_level': breed['energy_level'] ?? 5,
          'image': imageUrl,
        });
      }

      setState(() {
        _catBreeds = breeds;
        _allBreeds = breeds;
        _isLoading = false;
      });
    } else {
      throw Exception('Error ${response.statusCode} con The Cat API');
    }
  }

  Future<void> _fetchFromAlternativeAPI() async {
    final response = await http.get(
      Uri.parse('https://catfact.ninja/breeds?limit=50'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> breedsData = data['data'];
      
      List<Map<String, dynamic>> breeds = [];
      
      for (var breed in breedsData) {
        final breedName = breed['breed'] ?? 'Desconocido';
        final country = breed['country'] ?? 'Desconocido';
        
        breeds.add({
          'id': breedName.hashCode.toString(),
          'name': breedName,
          'description': 'Raza de gato originaria de $country.',
          'origin': country,
          'life_span': '12-15 años',
          'temperament': 'Temperamento variable según la raza',
          'weight': '3-6 kg',
          'intelligence': 5,
          'affection_level': 5,
          'energy_level': 5,
          'image': _getPlaceholderImage(breedName),
        });
      }

      setState(() {
        _catBreeds = breeds;
        _allBreeds = breeds;
        _isLoading = false;
      });
    } else {
      throw Exception('Error con API alternativa');
    }
  }

  void _toggleApiSource() {
    setState(() {
      _useAlternativeApi = !_useAlternativeApi;
      _searchController.clear();
    });
    fetchCatBreeds();
  }

  void _searchBreeds() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _catBreeds = _allBreeds;
      });
    } else {
      setState(() {
        _catBreeds = _allBreeds.where((breed) {
          return breed['name'].toString().toLowerCase().contains(query) ||
                 breed['origin'].toString().toLowerCase().contains(query) ||
                 breed['temperament'].toString().toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API de Razas de Gatos'),
        actions: [
          IconButton(
            icon: Icon(_useAlternativeApi ? Icons.api : Icons.pets),
            tooltip: _useAlternativeApi 
                ? 'Cambiar a The Cat API' 
                : 'Cambiar a API alternativa',
            onPressed: _isLoading ? null : _toggleApiSource,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _useAlternativeApi 
                ? 'Cargando desde API alternativa...' 
                : 'Cargando desde The Cat API...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 60),
              const SizedBox(height: 20),
              const Text(
                'Error al cargar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: fetchCatBreeds,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _toggleApiSource,
                child: Text(
                  _useAlternativeApi 
                    ? 'Usar The Cat API' 
                    : 'Usar API alternativa',
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar raza...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => _searchBreeds(),
                ),
              ),
              const SizedBox(width: 10),
              Chip(
                label: Text('${_catBreeds.length} razas'),
                backgroundColor: Colors.orange.shade100,
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _catBreeds.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 60, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'No se encontraron razas',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _catBreeds.length,
                  itemBuilder: (context, index) {
                    final breed = _catBreeds[index];
                    return _buildBreedCard(breed, context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBreedCard(Map<String, dynamic> breed, BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CatBreedDetailScreen(breed: breed),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.network(
                  breed['image'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.pets,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    breed['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          breed['origin'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        breed['life_span'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLevelIndicator('Afecto', breed['affection_level']),
                      _buildLevelIndicator('Energía', breed['energy_level']),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIndicator(String label, int level) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Container(
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: level / 10.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CatBreedDetailScreen extends StatelessWidget {
  final Map<String, dynamic> breed;

  const CatBreedDetailScreen({super.key, required this.breed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(breed['name']),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  breed['image'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(Icons.pets, size: 100, color: Colors.grey[400]),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildInfoSection(
              title: 'Información básica',
              children: [
                _buildInfoRow('Origen', breed['origin']),
                _buildInfoRow('Esperanza de vida', breed['life_span']),
                _buildInfoRow('Peso', breed['weight']),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildInfoSection(
              title: 'Descripción',
              children: [
                Text(
                  breed['description'],
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildInfoSection(
              title: 'Estadísticas',
              children: [
                _buildStatRow('Inteligencia', breed['intelligence']),
                _buildStatRow('Nivel de afecto', breed['affection_level']),
                _buildStatRow('Nivel de energía', breed['energy_level']),
              ],
            ),
            
            const SizedBox(height: 24),
            
            if ((breed['temperament'] as String).isNotEmpty)
              _buildInfoSection(
                title: 'Temperamento',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (breed['temperament'] as String)
                        .split(',')
                        .map((trait) => Chip(
                              label: Text(trait.trim()),
                              backgroundColor: Colors.orange.shade100,
                            ))
                        .toList(),
                  ),
                ],
              ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('$value/10'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value / 10.0,
            backgroundColor: Colors.grey[300],
            color: Colors.orange,
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}