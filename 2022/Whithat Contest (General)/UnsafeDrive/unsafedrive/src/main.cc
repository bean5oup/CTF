#include <iostream>
#include <cstring>

#include <unistd.h>

#include <drive.hh>

using namespace std;

void initialize() {
  setvbuf(stdin, nullptr, _IONBF, 0);
  setvbuf(stdout, nullptr, _IONBF, 0);
  setvbuf(stderr, nullptr, _IONBF, 0);
}

[[ noreturn ]] void error(const char* err) {
  cerr << err << endl;
  exit(1);
}

int main(int argc, char** argv, char** envp) {
  initialize();

  cout << "UnsafeDrive v0.7.13" << endl;
  drive::FileCache caches(0x10);
  drive::message::Msg msg;
  size_t idx, size;
  off_t offset;

  char buffer[0x100];
  uint8_t* res;

  memset(&msg, 0, sizeof(msg));
  memset(buffer, 0, sizeof(buffer));
  while (cin.good()) {
    cin.read(reinterpret_cast<char*>(&msg), sizeof(msg));
    if (cin.bad()) break;
    switch (msg.mode.request_mode) {
      case drive::message::request::kOpenDriveFile:
        if (msg.size > 0x40) {
          msg.mode.response_mode = drive::message::response::kError;
          goto NULL_MSG;
        }
        cin.read(buffer, msg.size);
        if (caches.open_file(buffer)) {
          msg.mode.response_mode = drive::message::response::kOk;
        } else {
          msg.mode.response_mode = drive::message::response::kError;
        }
        goto NULL_MSG;
      case drive::message::request::kLoadFile:
        if (msg.size != sizeof(size_t)) {
          msg.mode.response_mode = drive::message::response::kError;
          goto NULL_MSG;
        }
        cin.read(buffer, sizeof(size_t));
        idx = *reinterpret_cast<size_t*>(buffer);
        if (caches.load_file(idx)) {
          msg.mode.response_mode = drive::message::response::kOk;
        } else {
          msg.mode.response_mode = drive::message::response::kError;
        }
        goto NULL_MSG;
      case drive::message::request::kWrite:
        if (msg.size != sizeof(size_t)*2 + sizeof(off_t)) {
          msg.mode.response_mode = drive::message::response::kError;
          goto NULL_MSG;
        }
        cin.read(buffer, sizeof(size_t));
        idx = *reinterpret_cast<size_t*>(buffer);
        cin.read(buffer, sizeof(size_t));
        size = *reinterpret_cast<size_t*>(buffer);
        cin.read(buffer, sizeof(off_t));
        offset = *reinterpret_cast<size_t*>(buffer);
        if (caches.write(idx, size, offset)) {
          msg.mode.response_mode = drive::message::response::kOk;
        } else {
          msg.mode.response_mode = drive::message::response::kError;
        }
        goto NULL_MSG;
      case drive::message::request::kRead:
        if (msg.size != sizeof(size_t)*2 + sizeof(off_t)) {
          msg.mode.response_mode = drive::message::response::kError;
          goto NULL_MSG;
        }
        cin.read(buffer, sizeof(size_t));
        idx = *reinterpret_cast<size_t*>(buffer);
        cin.read(buffer, sizeof(size_t));
        size = *reinterpret_cast<size_t*>(buffer);
        cin.read(buffer, sizeof(off_t));
        offset = *reinterpret_cast<size_t*>(buffer);
        if ((res = caches.read(idx, size, offset)) != nullptr) {
          msg.mode.response_mode = drive::message::response::kOk;
          msg.size = size;
          cout.write(reinterpret_cast<char*>(&msg), sizeof(msg));
          cout.write(reinterpret_cast<char*>(res), size);
        } else {
          msg.mode.response_mode = drive::message::response::kError;
          goto NULL_MSG;
        }
        break;
      case drive::message::request::kCommit:
        if (msg.size != 0) {
          msg.mode.response_mode = drive::message::response::kError;
          goto NULL_MSG;
        }
        if (caches.commit()) {
          msg.mode.response_mode = drive::message::response::kOk;
        } else {
          msg.mode.response_mode = drive::message::response::kError;
        }
        goto NULL_MSG;
      default:
        msg.mode.response_mode = drive::message::response::kUnknownRequest;
NULL_MSG:
        msg.size = 0;
        cout.write(reinterpret_cast<char*>(&msg), sizeof(msg));
        break;
    }
    cout.flush();
  }

  return 0;
}
