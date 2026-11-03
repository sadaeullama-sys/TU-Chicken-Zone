import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';

void main() => runApp(const ChickenZoneApp());

class ChickenZoneApp extends StatelessWidget {
  const ChickenZoneApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'TU Chicken Zone',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff087f5b)), useMaterial3: true),
    home: const HomePage(),
  );
}

class Entry {
  String name, category;
  int kg, gram;
  double rate, received;
  Entry(this.name,this.category,this.kg,this.gram,this.rate,this.received);
  double get weight => kg + gram / 1000;
  double get total => weight * rate;
  double get balance => total - received;
  Map<String,dynamic> toJson()=>{'name':name,'category':category,'kg':kg,'gram':gram,'rate':rate,'received':received};
  factory Entry.fromJson(Map<String,dynamic> j)=>Entry(j['name'],j['category'],j['kg'],j['gram'],(j['rate'] as num).toDouble(),(j['received'] as num).toDouble());
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage> {
  int tab=0; List<Entry> entries=[]; String shopName='TU Chicken Zone';
  @override void initState(){super.initState(); load();}
  Future<void> load() async {final p=await SharedPreferences.getInstance(); final raw=p.getString('entries')??'[]'; setState(()=>{entries=(jsonDecode(raw) as List).map((e)=>Entry.fromJson(e)).toList(),shopName=p.getString('shopName')??'TU Chicken Zone'});}
  Future<void> save() async {final p=await SharedPreferences.getInstance(); await p.setString('entries',jsonEncode(entries.map((e)=>e.toJson()).toList()));}\n  Future<void> editShopName() async {final ctrl=TextEditingController(text:shopName); await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Change Shop Name / دکان کا نام تبدیل کریں'),content:TextField(controller:ctrl,autofocus:true,decoration:const InputDecoration(labelText:'Shop Name')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:() async {final value=ctrl.text.trim();if(value.isNotEmpty){final p=await SharedPreferences.getInstance();await p.setString('shopName',value);setState(()=>shopName=value);}if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Save'))]));}
  double get sum=>entries.fold(0,(a,e)=>a+e.total);
  Future<void> addEntry() async {
    final name=TextEditingController(), kg=TextEditingController(text:'0'), gr=TextEditingController(text:'0'), rate=TextEditingController(text:'0'), rec=TextEditingController(text:'0');
    String category='Mall';
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
      title:const Text('Add Record / نیا ریکارڈ'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Customer / کسٹمر')),
        DropdownButtonFormField(value:category,items:['Mall','Kami'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setD(()=>category=v!)),
        Row(children:[Expanded(child:TextField(controller:kg,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'KG'))),const SizedBox(width:8),Expanded(child:TextField(controller:gr,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Gram')))]),
        TextField(controller:rate,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Rate Rs/KG')),
        TextField(controller:rec,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Received Rs')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:(){if(name.text.trim().isNotEmpty){setState(()=>entries.add(Entry(name.text.trim(),category,int.tryParse(kg.text)??0,int.tryParse(gr.text)??0,double.tryParse(rate.text)??0,double.tryParse(rec.text)??0)));save();Navigator.pop(ctx);}},child:const Text('Save'))],
    )));
  }
  Future<void> exportPdf() async {final doc=pw.Document();doc.addPage(pw.MultiPage(build:(c)=>[pw.Header(level:0,child:pw.Text('$shopName - Customer Ledger')),pw.Table.fromTextArray(headers:['Customer','Type','Weight','Rate','Total','Received','Balance'],data:entries.map((e)=>[e.name,e.category,'${e.kg} KG ${e.gram} g',e.rate.toStringAsFixed(2),e.total.toStringAsFixed(2),e.received.toStringAsFixed(2),e.balance.toStringAsFixed(2)]).toList())]));await Printing.layoutPdf(onLayout:(format)=>doc.save());}
  @override Widget build(BuildContext context){final filtered=entries.where((e)=>tab==0|| (tab==1?e.category=='Mall':tab==2?e.category=='Kami':true)).toList();return Scaffold(
    appBar:AppBar(title:Text(shopName),actions:[IconButton(tooltip:'Change shop name',onPressed:editShopName,icon:const Icon(Icons.edit)),IconButton(onPressed:exportPdf,icon:const Icon(Icons.picture_as_pdf))]),
    floatingActionButton:FloatingActionButton.extended(onPressed:addEntry,icon:const Icon(Icons.add),label:const Text('Add Record')),
    body:Column(children:[Card(margin:const EdgeInsets.all(12),child:ListTile(title:const Text('Total Mall/Kami Amount'),subtitle:Text('Rs. ${sum.toStringAsFixed(2)}'),leading:const Icon(Icons.account_balance_wallet))),
      Expanded(child:filtered.isEmpty?const Center(child:Text('No records yet / ابھی ریکارڈ نہیں')):ListView.builder(itemCount:filtered.length,itemBuilder:(c,i){final e=filtered[i];return Card(child:ListTile(title:Text(e.name),subtitle:Text('${e.category} • ${e.kg} KG + ${e.gram} Gram • Rs ${e.rate}/KG\nTotal Rs ${e.total.toStringAsFixed(2)} | Received Rs ${e.received.toStringAsFixed(2)}'),isThreeLine:true,trailing:Text('Due\n${e.balance.toStringAsFixed(0)}',textAlign:TextAlign.center)));})),
    ]),
    bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.home),label:'Home'),NavigationDestination(icon:Icon(Icons.scale),label:'Mall'),NavigationDestination(icon:Icon(Icons.remove_circle),label:'Kami'),NavigationDestination(icon:Icon(Icons.people),label:'Customers')]),
  );}
}
