import 'dart:convert';
import 'dart:html';

class Todo {
  final int id;
  final String text;
  final bool complete;

  Todo({this.id, this.text, this.complete});
  Todo.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        text = json['text'],
        complete = json['complete'];
  Map<String, dynamic> toJson() =>
      {'id': id, 'text': text, 'complete': complete};
}

class Model {
  List<Todo> todos = [];
  void Function(List<Todo> todos) onTodoListChanged;

  Model() {
    final items = json.decode(window.localStorage['todos'] ?? '[]') as List;
    if (items.isNotEmpty) {
      todos = items.map((item) => Todo.fromJson(item)).toList();
    }
  }
  void _commit(List<Todo> todos) {
    onTodoListChanged(todos);
    window.localStorage['todos'] =
        json.encode(todos.map((todo) => todo.toJson()).toList());
  }

  void addTodo(String todoText) {
    final todo = Todo(
        id: todos.isNotEmpty ? todos[todos.length - 1].id + 1 : 1,
        text: todoText,
        complete: false);
    todos.add(todo);
    _commit(todos);
  }

  void editTodo(int id, String updatedText) {
    todos = todos
        .map((todo) => todo.id == id
            ? Todo(id: todo.id, text: updatedText, complete: todo.complete)
            : todo)
        .toList();

    _commit(todos);
  }

  void deleteTodo(int id) {
    todos = todos.where((todo) => todo.id != id).toList();
    _commit(todos);
  }

  void toggleTodo(int id) {
    todos = todos
        .map((todo) => todo.id == id
            ? Todo(id: todo.id, text: todo.text, complete: !todo.complete)
            : todo)
        .toList();

    _commit(todos);
  }

  void bindTodoListChanged(void Function(List<Todo> todos) callback) {
    onTodoListChanged = callback;
  }
}

class View {
  DivElement app;
  HeadingElement title;
  FormElement form;
  InputElement input;
  ButtonElement submitButton;
  UListElement todoList;

  String _temporaryTodoText = '';

  View() {
    app = getElement('#root');

    title = createElement('h1');
    title.text = 'Todos';

    form = createElement('form');

    input = createElement('input');
    input.type = 'text';
    input.placeholder = 'Add todo';
    input.name = 'todo';

    submitButton = createElement('button');
    submitButton.text = 'Submit';

    todoList = createElement('ul', 'todo-list');

    form.append(input);
    form.append(submitButton);

    app.append(title);
    app.append(form);
    app.append(todoList);

    _initLocalListeners();
  }

  String get _todoText => input.value;
  void _resetInput() => input.value = '';

  Element getElement(String selector) {
    final element = querySelector(selector);
    return element;
  }

  Element createElement(String tagName, [String className]) {
    final element = document.createElement(tagName);
    if (className != null) element.classes.add(className);

    return element;
  }

  void displayTodos(List<Todo> todos) {
    while (todoList.firstChild != null) {
      todoList.firstChild.remove();
      // todoList.nodes.remove(todoList.firstChild);
      // todoList.childNodes.removeAt(0);
    }

    if (todos.isEmpty) {
      final ParagraphElement p = createElement('p');
      p.text = 'Nothing to do! Add a task?';
      todoList.append(p);
    } else {
      todos.forEach((todo) {
        final LIElement li = createElement('li');
        li.id = todo.id.toString();

        final InputElement checkbox = createElement('input');
        checkbox.type = 'checkbox';
        checkbox.checked = todo.complete;

        final SpanElement span = createElement('span', 'editable');
        span.contentEditable = 'true';

        if (todo.complete) {
          final strike = createElement('s');
          strike.text = todo.text;
          span.append(strike);
        } else {
          span.text = todo.text;
        }

        final ButtonElement deleteButton = createElement('button', 'delete');
        deleteButton.text = 'Delete';
        li.append(checkbox);
        li.append(span);
        li.append(deleteButton);

        todoList.append(li);
      });
    }
  }

  void bindAddTodo(void Function(String todoText) handler) {
    form.addEventListener('submit', (event) {
      event.preventDefault();
      if (_todoText.isNotEmpty) {
        handler(_todoText);
        _resetInput();
      }
    });
  }

  void bindDeleteTodo(void Function(int id) handler) {
    todoList.addEventListener('click', (event) {
      if (event.target.toString() == 'button') {
        final ButtonElement targetElement = event.target;
        if (targetElement.className == 'delete') {
          final id = int.parse(targetElement.parent.id);

          handler(id);
        }
      }
    });
  }

  void bindToggleTodo(void Function(int id) handler) {
    todoList.addEventListener('change', (event) {
      if (event.target.toString() == 'input') {
        final CheckboxInputElement targetElement = event.target;
        if (targetElement != null) {
          final id = int.parse(targetElement.parent.id);

          handler(id);
        }
      }
    });
  }

  void bindEditTodo(void Function(int id, String temporaryTodoText) handler) {
    todoList.addEventListener('focusout', (event) {
      if (event.target.toString() == 'span') {
        final SpanElement targetElement = event.target;
        if (_temporaryTodoText != '') {
          final id = int.parse(targetElement.parent.id);

          handler(id, _temporaryTodoText);
          _temporaryTodoText = '';
        }
      }
    });
  }

  void _initLocalListeners() {
    todoList.addEventListener('input', (event) {
      if (event.target.toString() == 'span') {
        final SpanElement targetElement = event.target;
        if (targetElement.classes.contains('editable')) {
          _temporaryTodoText = targetElement.text;
        }
      }
    });
  }
}

class Controller {
  Model model;
  View view;

  Controller(this.model, this.view) {
    onTodoListChanged(model.todos);
    view.bindAddTodo(handleAddTodo);
    view.bindDeleteTodo(handleDeleteTodo);
    view.bindToggleTodo(handleToggleTodo);
    view.bindEditTodo(handleEditTodo);

    model.bindTodoListChanged(onTodoListChanged);
  }

  void onTodoListChanged(List<Todo> todos) => view.displayTodos(todos);
  void handleAddTodo(String todoText) => model.addTodo(todoText);
  void handleDeleteTodo(int id) => model.deleteTodo(id);
  void handleToggleTodo(int id) => model.toggleTodo(id);
  void handleEditTodo(int id, String updatedText) =>
      model.editTodo(id, updatedText);
}

void main() {
  Controller(Model(), View());
}
