import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const MerceariaApp());
}

class MerceariaApp extends StatelessWidget {
  const MerceariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caixa da Mercearia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProdutosPage(onChanged: () => setState(() {})),
      VendasPage(onChanged: () => setState(() {})),
      ResumoPage(onChanged: () => setState(() {})),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caixa da Mercearia'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2),
            label: 'Produtos',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale),
            label: 'Vendas',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart),
            label: 'Resumo',
          ),
        ],
      ),
    );
  }
}

class Produto {
  final int? id;
  final String codigoBarras;
  final String nome;
  final double preco;

  Produto({this.id, required this.codigoBarras, required this.nome, required this.preco});
}

class Venda {
  final int? id;
  final String codigoBarras;
  final String nomeProduto;
  final double valorTotal;
  final int quantidade;
  final String metodo;
  final String data;

  Venda({
    this.id,
    required this.codigoBarras,
    required this.nomeProduto,
    required this.valorTotal,
    required this.quantidade,
    required this.metodo,
    required this.data,
  });
}

class MockMerceariaDB {
  static final MockMerceariaDB instance = MockMerceariaDB._internal();
  MockMerceariaDB._internal();

  final List<Produto> produtos = [
    Produto(id: 1, codigoBarras: '789100', nome: 'Arroz 5kg', preco: 28.50),
    Produto(id: 2, codigoBarras: '789200', nome: 'Feijão 1kg', preco: 8.90),
    Produto(id: 3, codigoBarras: '789300', nome: 'Óleo de Soja', preco: 7.50),
  ];

  final List<Venda> vendas = [
    Venda(
      id: 1,
      codigoBarras: '789100',
      nomeProduto: 'Arroz 5kg',
      valorTotal: 28.50,
      quantidade: 1,
      metodo: 'especie',
      data: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    ),
  ];

  Future<List<Produto>> listarProdutos() async => produtos;

  Future<void> criarProduto(Produto p) async {
    final novoId = (produtos.isEmpty ? 0 : produtos.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
    produtos.add(Produto(id: novoId, codigoBarras: p.codigoBarras, nome: p.nome, preco: p.preco));
  }

  Future<List<Venda>> listarVendas({required String mesYYYYMM}) async {
    return vendas.where((v) => v.data.startsWith(mesYYYYMM)).toList()..sort((a, b) => b.data.compareTo(a.data));
  }

  Future<void> criarVenda(Venda v) async {
    final novoId = (vendas.isEmpty ? 0 : vendas.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
    vendas.add(Venda(id: novoId, codigoBarras: v.codigoBarras, nomeProduto: v.nomeProduto, valorTotal: v.valorTotal, quantidade: v.quantidade, metodo: v.metodo, data: v.data));
  }

  Future<void> deletarVenda(int id) async {
    vendas.removeWhere((v) => v.id == id);
  }

  Future<Map<String, double>> resumoMes({required String mesYYYYMM}) async {
    final itens = await listarVendas(mesYYYYMM: mesYYYYMM);
    double total = itens.fold(0, (sum, v) => sum + v.valorTotal);
    return {'faturamento': total};
  }
}

class ProdutosPage extends StatefulWidget {
  final VoidCallback onChanged;
  const ProdutosPage({super.key, required this.onChanged});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  final MockMerceariaDB _db = MockMerceariaDB.instance;
  List<Produto> _produtos = [];
  bool _loading = true;

  Future<void> _load() async {
    final lista = await _db.listarProdutos();
    if (!mounted) return;
    setState(() { _produtos = lista; _loading = false; });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _adicionarProduto() async {
    String codigo = '';
    String nome = '';
    double preco = 0;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cadastrar Produto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Código de Barras'), onChanged: (v) => codigo = v),
            TextField(decoration: const InputDecoration(labelText: 'Nome do Produto'), onChanged: (v) => nome = v),
            TextField(keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Preço (R\$)'), onChanged: (v) => preco = double.tryParse(v.replaceAll(',', '.')) ?? 0),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar'))],
      ),
    );
    if (result == true) { await _db.criarProduto(Produto(codigoBarras: codigo, nome: nome, preco: preco)); widget.onChanged(); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: _produtos.length, itemBuilder: (context, i) { final p = _produtos[i]; return ListTile(leading: const CircleAvatar(child: Icon(Icons.shopping_bag)), title: Text(p.nome), subtitle: Text('Cód: ${p.codigoBarras}'), trailing: Text('R\$ ${p.preco.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))); })),
        Padding(padding: const EdgeInsets.all(14), child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _adicionarProduto, icon: const Icon(Icons.add), label: const Text('Cadastrar produto')))),
      ],
    );
  }
}

class VendasPage extends StatefulWidget {
  final VoidCallback onChanged;
  const VendasPage({super.key, required this.onChanged});

  @override
  State<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends State<VendasPage> {
  final MockMerceariaDB _db = MockMerceariaDB.instance;
  List<Venda> _vendas = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
  String get _mesYYYYMM => DateFormat('yyyy-MM').format(_selectedDate);

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _db.listarVendas(mesYYYYMM: _mesYYYYMM);
    if (!mounted) return;
    setState(() { _vendas = list; _loading = false; });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _registrarVenda() async {
    final produtos = await _db.listarProdutos();
    Produto pSel = produtos.first;
    int qtd = 1;
    String metodo = 'especie';
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setD) => AlertDialog(
      title: const Text('Registrar Venda'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<Produto>(value: pSel, items: produtos.map((p) => DropdownMenuItem(value: p, child: Text(p.nome))).toList(), onChanged: (p) => setD(() => pSel = p!)),
        TextField(decoration: const InputDecoration(labelText: 'Quantidade'), onChanged: (v) => qtd = int.tryParse(v) ?? 1),
        DropdownButtonFormField<String>(value: metodo, items: const [DropdownMenuItem(value: 'especie', child: Text('Dinheiro')), DropdownMenuItem(value: 'pix', child: Text('Pix'))], onChanged: (v) => setD(() => metodo = v!)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () async { await _db.criarVenda(Venda(codigoBarras: pSel.codigoBarras, nomeProduto: pSel.nome, valorTotal: pSel.preco * qtd, quantidade: qtd, metodo: metodo, data: DateFormat('yyyy-MM-dd').format(_selectedDate))); Navigator.pop(ctx); widget.onChanged(); _load(); }, child: const Text('Salvar'))],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [IconButton(onPressed: () { setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1)); _load(); }, icon: const Icon(Icons.chevron_left)), Text(DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate)), IconButton(onPressed: () { setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1)); _load(); }, icon: const Icon(Icons.chevron_right))]),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: _vendas.length, itemBuilder: (context, i) { final v = _vendas[i]; return ListTile(title: Text('${v.quantidade}x ${v.nomeProduto}'), trailing: Text('R\$ ${v.valorTotal.toStringAsFixed(2)}'), onTap: () async { await _db.deletarVenda(v.id!); widget.onChanged(); _load(); }); })),
      Padding(padding: const EdgeInsets.all(14), child: FilledButton.icon(onPressed: _registrarVenda, icon: const Icon(Icons.add), label: const Text('Nova Venda'))),
    ]);
  }
}

class ResumoPage extends StatefulWidget {
  final VoidCallback onChanged;
  const ResumoPage({super.key, required this.onChanged});

  @override
  State<ResumoPage> createState() => _ResumoPageState();
}

class _ResumoPageState extends State<ResumoPage> {
  final MockMerceariaDB _db = MockMerceariaDB.instance;
  double _total = 0;
  bool _loading = true;

  Future<void> _load() async {
    final res = await _db.resumoMes(mesYYYYMM: DateFormat('yyyy-MM').format(DateTime.now()));
    if (!mounted) return;
    setState(() { _total = res['faturamento']!; _loading = false; });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: _loading ? const CircularProgressIndicator() : Card(child: ListTile(title: const Text('Faturamento Mensal'), trailing: Text('R\$ ${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))));
  }
}
