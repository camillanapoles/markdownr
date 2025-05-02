import 'package:html2md/html2md.dart' as html2md;
import 'package:intl/intl.dart';
import 'package:markdownr/notifications.dart';
import 'package:markdownr/readability.dart';
import 'package:markdownr/httpclient.dart';

class MarkdownArticle {
  const MarkdownArticle({
    required this.url,
    required this.content,
    required this.title,
    required this.author,
    required this.excerpt,
    required this.creationDate,
  });

  final String url;
  final String content;
  final String title;
  final String author;
  final String excerpt;
  final String creationDate;

  String get frontMatter =>
      "---\ncreated: $creationDate\nsource: $url\nauthor: $author\n---\n\n";

  String get sourceLinkSection => "Clipped from: $url\n\n";

  String get excerptSection => "## Excerpt\n\n> $excerpt\n\n";
}

class ChatbotConversation {
  const ChatbotConversation({
    required this.url,
    required this.title,
    required this.messages,
    required this.creationDate,
  });

  final String url;
  final String title;
  final List<ChatMessage> messages;
  final String creationDate;

  String get frontMatter =>
      "---\ncreated: $creationDate\nsource: $url\ntype: conversation\n---\n\n";

  String get sourceLinkSection => "Clipped from: $url\n\n";

  String formatConversation() {
    StringBuffer buffer = StringBuffer();
    buffer.write("# $title\n\n");
    
    for (var message in messages) {
      buffer.write("## ${message.role}\n\n");
      buffer.write("${message.content}\n\n");
    }
    
    return buffer.toString();
  }
}

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
  });

  final String role;
  final String content;
}

class Url2MdConverter {
  Url2MdConverter({
    required HttpClient httpClient,
    required NotificationService notificationService,
    required ReadabilityService readabilityService,
  })  : _httpClient = httpClient,
        _notificationService = notificationService,
        _readabilityService = readabilityService;

  final HttpClient _httpClient;
  final NotificationService _notificationService;
  final ReadabilityService _readabilityService;

  Future<MarkdownArticle> convertPage({required String url}) async {
    var dateFmt = DateFormat("yyyy-MM-ddThh:mm:ss");
    var formattedDate = dateFmt.format(DateTime.now());
    try {
      var html = await _httpClient.getPage(url);
      var readableResults = await _readabilityService.makeReadable(html, url);
      var markdown = html2md.convert(readableResults.content, styleOptions: {
        "headingStyle": "atx",
        "hr": "---",
        "bulletListMarker": "-",
        "codeBlockStyle": "fenced",
      }, rules: [
        jeckyllRule
      ]);
      return MarkdownArticle(
          url: url,
          content: markdown,
          title: readableResults.title,
          author: readableResults.author,
          excerpt: readableResults.excerpt,
          creationDate: formattedDate);
    } catch (e) {
      _notificationService.showToast("$e");
      return MarkdownArticle(
          url: url,
          content: "",
          title: "",
          author: "",
          excerpt: "",
          creationDate: formattedDate);
    }
  }
  
  Future<ChatbotConversation?> detectChatbotConversation({required String url}) async {
    var dateFmt = DateFormat("yyyy-MM-ddThh:mm:ss");
    var formattedDate = dateFmt.format(DateTime.now());
    try {
      var html = await _httpClient.getPage(url);
      var readableResults = await _readabilityService.makeReadable(html, url);
      
      // Aqui vamos analisar o HTML para detectar padrões de conversa de chatbot
      List<ChatMessage> messages = _extractChatMessages(readableResults.content);
      
      if (messages.isNotEmpty) {
        return ChatbotConversation(
          url: url,
          title: readableResults.title,
          messages: messages,
          creationDate: formattedDate
        );
      }
      return null;
    } catch (e) {
      _notificationService.showToast("$e");
      return null;
    }
  }
  
  List<ChatMessage> _extractChatMessages(String html) {
    List<ChatMessage> messages = [];
    
    // Padrões comuns para ChatGPT, Bard e outros chatbots
    // Detectar padrões como divs alternados, classes específicas, etc.
    
    // Exemplo simplificado para ChatGPT:
    RegExp chatGptPattern = RegExp(
      r'<div[^>]*class="[^"]*message[^"]*"[^>]*>\s*<div[^>]*class="[^"]*(?:user|assistant)[^"]*"[^>]*>(.*?)<\/div>',
      caseSensitive: false,
      dotAll: true
    );
    
    var matches = chatGptPattern.allMatches(html);
    
    for (var match in matches) {
      String content = match.group(1) ?? "";
      String role = content.contains("user") ? "Human" : "Assistant";
      
      // Limpar o conteúdo HTML
      content = html2md.convert(content);
      
      if (content.isNotEmpty) {
        messages.add(ChatMessage(role: role, content: content));
      }
    }
    
    // Adicionar mais padrões para outros chatbots
    
    return messages;
  }

  html2md.Rule jeckyllRule = html2md.Rule('jekyll-codeblocks',
      filterFn: (node) => node.nodeName == 'code' && node.parentElName == 'pre',
      replacement: (content, node) {
        var language = getLanguage(node);
        var content = node.childNodes().map((e) => e.textContent).join();
        return '\n\n```$language\n$content\n```\n\n';
      });
}

String getLanguage(node) {
  var regex = RegExp(r'language-(\S+)');
  var className = node.firstChild!.className;
  var languageMatched = regex.firstMatch(className)?.group(1);
  if (languageMatched != null) {
    return languageMatched;
  }
  var nodeElement = node.asElement();
  while (nodeElement.parent != null) {
    nodeElement = nodeElement.parent;
    for (var className in nodeElement.classes) {
      languageMatched = regex.firstMatch(className)?.group(1);
      if (languageMatched != null) {
        return languageMatched;
      }
    }
  }
  return '';
}
