#ifndef DRIVE_HH_
#define DRIVE_HH_

#include <memory>
#include <fstream>
#include <vector>
#include <cstdint>

namespace drive {
  namespace message {
    namespace request {
      enum Mode {
        kOpenDriveFile,
        kLoadFile,
        kWrite,
        kRead,
        kCommit,
      };
    }

    namespace response {
      enum Mode {
        kOk,
        kError,
        kUnknownRequest,
      };
    }

    struct Msg {
      union {
        request::Mode request_mode;
        response::Mode response_mode;
      } mode;
      size_t size;
    };
  }

  struct CacheElem {
    std::unique_ptr<std::fstream> fs;
    char* name;
    uint8_t* buffer;
    size_t size;
    bool dirty;
  };

  class FileCache {
    public:
      bool open_file(char* name);
      bool load_file(size_t idx);
      bool commit();
      bool write(size_t idx, size_t size, off_t offset);
      uint8_t* read(size_t idx, size_t size, off_t offset);
      CacheElem* search(char* name);
      FileCache(int size);
    private:
      std::vector<CacheElem*> cache;
  };
}

#endif
