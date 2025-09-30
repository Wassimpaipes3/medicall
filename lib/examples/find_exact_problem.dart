import 'comprehensive_diagnostic.dart';

/// Simple function to find the exact problem - just call this!
Future<void> findExactProblem() async {
  print('🔍 FINDING THE EXACT PROBLEM...\n');
  
  // Run comprehensive diagnostic
  await ComprehensiveDiagnostic.runDiagnostic();
  
  // Print summary
  ComprehensiveDiagnostic.printSummary();
  
  print('\n🎯 NEXT STEPS:');
  print('After running this diagnostic, you will know exactly what\'s wrong.');
  print('Look for any ❌ CRITICAL errors in the output above.');
  print('The diagnostic will tell you exactly what to fix.');
}

/// Quick check - just see if you have any documents
Future<void> quickDocumentCheck() async {
  print('⚡ QUICK CHECK - Do you have provider documents?\n');
  
  await ComprehensiveDiagnostic._findAllDocuments();
  
  print('\n💡 If you see "❌ No documents found", you need to create a provider document first.');
  print('   If you see documents but updates fail, check the error messages above.');
}

