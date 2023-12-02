import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => RepositoryProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub API App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GitHub Repositories'),
      ),
      body: Consumer<RepositoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (provider.hasError) {
            return Center(
              child: Text('Error loading repositories'),
            );
          } else {
            return RepositoryList(provider.repositories);
          }
        },
      ),
    );
  }
}

class RepositoryList extends StatelessWidget {
  final List<Repository> repositories;

  RepositoryList(this.repositories);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        return RepositoryListItem(repositories[index]);
      },
    );
  }
}

class RepositoryListItem extends StatelessWidget {
  final Repository repository;

  RepositoryListItem(this.repository);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(repository.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(repository.description),
          Text('Visibility: ${repository.visibility}'),
          Text('Forks: ${repository.forks}'),
          Text('Open Issues: ${repository.openIssues}'),
          Text('Watchers: ${repository.watchers}'),
          Text('Default Branch: ${repository.defaultBranch}'),
          if (repository.lastCommitSha.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last Commit: ${repository.lastCommitMessage}'),
                Text('Author: ${repository.lastCommitAuthor}'),
                Text('Date: ${repository.lastCommitDate.toLocal()}'),
              ],
            ),
        ],
      ),
      onTap: () {
        Provider.of<RepositoryProvider>(context, listen: false).fetchLastCommit(repository);
        // Add navigation or any other action when a repository is tapped
      },
      trailing: Icon(Icons.arrow_forward),
    );
  }
}



class RepositoryProvider with ChangeNotifier {
  List<Repository> _repositories = [];
  bool _isLoading = true;
  bool _hasError = false;

  RepositoryProvider() {
    fetchRepositories();
  }

  List<Repository> get repositories => _repositories;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> fetchRepositories() async {
  try {
    final response = await http.get(Uri.parse('https://api.github.com/users/freeCodeCamp/repos'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      _repositories = data.map((repo) => Repository.fromJson(repo)).toList();
    } else {
      print('Error loading repositories. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      _hasError = true;
    }
  } catch (e, stackTrace) {
    print('Error loading repositories: $e');
    print('Stack trace: $stackTrace');
    _hasError = true;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> fetchLastCommit(Repository repo) async {
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/freeCodeCamp/${repo.name}/commits'));

      if (response.statusCode == 200) {
        List<dynamic> commits = json.decode(response.body);
        if (commits.isNotEmpty) {
          Map<String, dynamic> lastCommit = commits.first['commit'];
          repo.lastCommitSha = commits.first['sha'] ?? '';
          repo.lastCommitMessage = lastCommit['message'] ?? '';
          repo.lastCommitAuthor = lastCommit['author']['name'] ?? '';
          repo.lastCommitDate = DateTime.parse(lastCommit['author']['date'] ?? '');
        }
      } else {
        print('Error loading last commit for ${repo.name}. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error loading last commit for ${repo.name}: $e');
      print('Stack trace: $stackTrace');
    } finally {
      notifyListeners();
    }
  }

}

class Repository {
  final String name;
  final String description;
  final String visibility;
  final int forks;
  final int openIssues;
  final int watchers;
  final String defaultBranch;
  String lastCommitSha;
  String lastCommitMessage;
  String lastCommitAuthor;
  DateTime lastCommitDate;

  Repository({
    required this.name,
    required this.description,
    required this.visibility,
    required this.forks,
    required this.openIssues,
    required this.watchers,
    required this.defaultBranch,
    required this.lastCommitSha,
    required this.lastCommitMessage,
    required this.lastCommitAuthor,
    required this.lastCommitDate,
  });

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      visibility: json['visibility'] ?? 'public',
      forks: json['forks'] ?? 0,
      openIssues: json['open_issues'] ?? 0,
      watchers: json['watchers'] ?? 0,
      defaultBranch: json['default_branch'] ?? 'main',
      lastCommitSha: '', // initialize to empty string
      lastCommitMessage: '',
      lastCommitAuthor: '',
      lastCommitDate: DateTime.now(), // initialize to current date/time
    );
  }
}


