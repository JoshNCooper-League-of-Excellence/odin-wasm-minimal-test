

#include <chrono>
#include <functional>
#include <map>
#include <print>
#include <string.h>
#include <string>
#include <sys/inotify.h>
#include <unistd.h>

struct FileWatcher {
  bool watching = false;
  std::function<void(const std::string &)> onModify;
  std::function<void(const std::string &)> onCreate;
  std::function<void(const std::string &)> onDelete;
  std::map<std::string, std::chrono::steady_clock::time_point> last_events;
  const std::chrono::milliseconds debounce_time{100};

  enum struct CallbackKind { MODIFY, CREATE, DELETE };

  void setCallback(CallbackKind kind,
                   const std::function<void(const std::string &)> &callback) {
    switch (kind) {
    case CallbackKind::MODIFY:
      onModify = callback;
      break;
    case CallbackKind::CREATE:
      onCreate = callback;
      break;
    case CallbackKind::DELETE:
      onDelete = callback;
      break;
    }
  }

  void init() {
    inotify_fd = inotify_init();
    if (inotify_fd == -1) {
      std::println("Error initializing inotify");
      exit(EXIT_FAILURE);
    }
  }

  FileWatcher() { init(); }

  void watchDirectory(const std::string &path) {
    watch_fd = inotify_add_watch(inotify_fd, path.c_str(),
                                 IN_MODIFY | IN_CREATE | IN_DELETE);

    if (watch_fd == -1) {
      std::println("Error adding watch for {}", path);
      exit(EXIT_FAILURE);
    }

    watch_descriptors[watch_fd] = path;
  }

  void stopWatching() { watching = false; }


  bool shouldProcessEvent(const std::string &filename) {
    auto now = std::chrono::steady_clock::now();
    auto &last = last_events[filename];

    if (now - last < debounce_time) {
      last = now;
      return false;
    }

    last = now;
    return true;
  }

  void startWatching() {
    watching = true;
    while (watching) {
      int length = read(inotify_fd, buffer, buffer_size);

      if (length < 0) {
        std::println("Error reading inotify events");
        exit(EXIT_FAILURE);
      }

      for (int i = 0; i < length;) {
        inotify_event *event = reinterpret_cast<inotify_event *>(&buffer[i]);
        if (event->len) {
          std::string filename(event->name);
          std::string path = watch_descriptors[event->wd];

          if (shouldProcessEvent(filename)) {
            if ((event->mask & IN_MODIFY) && onModify)
              onModify(filename);
            if ((event->mask & IN_CREATE) && onCreate)
              onCreate(filename);
            if ((event->mask & IN_DELETE) && onDelete)
              onDelete(filename);
          }
        }
        i += event_size + event->len;
      }
    }
  }

  ~FileWatcher() {
    for (const auto &wd : watch_descriptors) {
      inotify_rm_watch(inotify_fd, wd.first);
    }
    close(inotify_fd);
  }
  int inotify_fd;
  int watch_fd;
  std::map<int, std::string> watch_descriptors;
  const size_t event_size = sizeof(inotify_event);
  const size_t buffer_size = 1024 * (event_size + 16);
  char buffer[1024 * (sizeof(inotify_event) + 16)];
};
void process_command_line_args(char **argv, FileWatcher &watcher) {
  std::string kind{argv[1]};
  std::string command{argv[2]};
  command = "./" + command;

  if (kind == "MODIFY") {
    watcher.setCallback(FileWatcher::CallbackKind::MODIFY,
                        [command](const std::string &path) {
                          auto out_command = (command + " " + path);
                          std::system(out_command.c_str());
                        });
  } else if (kind == "CREATE") {
    watcher.setCallback(FileWatcher::CallbackKind::CREATE,
                        [command](const std::string &path) {
                          std::system((command + " " + path).c_str());
                        });
  } else if (kind == "DELETE") {
    watcher.setCallback(FileWatcher::CallbackKind::DELETE,
                        [command](const std::string &path) {
                          std::system((command + " " + path).c_str());
                        });
  } else {
    std::println("Invalid kind: {}. available kinds:\nCREATE\nMODIFY\nDELETE",
                 kind);
    exit(EXIT_FAILURE);
  }
}
int main(int argc, char **argv) {
  if (argc < 3) {
    std::println("Usage: ./watcher <KIND> <bash command to execute on "
                 "changed>\n Available 'KIND's:\nCREATE\nMODIFY\nDELETE",
                 argv[0]);
    exit(EXIT_FAILURE);
  }

  FileWatcher watcher;
  process_command_line_args(argv, watcher);

  watcher.watchDirectory(".");
  watcher.startWatching();
  return 0;
}
