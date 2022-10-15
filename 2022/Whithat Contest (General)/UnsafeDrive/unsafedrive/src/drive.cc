#include <drive.hh>
#include <fstream>
#include <memory>
#include <cstring>
#include <bits/stdc++.h>

namespace drive {
  FileCache::FileCache(int size) {
    this->cache.reserve(size);
  }

  bool FileCache::open_file(char* name) {
    if (strchr(name, '.') != nullptr || strchr(name, '/') != nullptr) return false;

    if (this->search(name) != nullptr) return false;

    std::unique_ptr<std::fstream> fs = std::make_unique<std::fstream>();
    std::string path = "/home/ctf/drive/";
    path += name;

    fs->open(path, std::fstream::binary | std::fstream::ate | std::fstream::in | std::fstream::out);
    if (fs->fail()) {
      fs->open(path, std::fstream::binary | std::fstream::ate | std::fstream::in | std::fstream::out | std::fstream::trunc);
      if (fs->fail()) return false;
    }

    size_t size = fs->tellg();
    uint8_t* buffer = nullptr;
    if (size != 0) {
      buffer = static_cast<uint8_t*>(malloc(size));
    }
    this->cache.push_back(new CacheElem { std::move(fs), strdup(name), buffer, size, false });

    return true;
  }

  bool FileCache::load_file(size_t idx) {
    if (idx >= this->cache.size()) return false;
    auto elem = this->cache[idx];

    if (elem->buffer == nullptr || elem->size == 0) return false;

    elem->fs->seekg(std::fstream::beg);
    off_t offset = 0;
    do {
      elem->fs->read(reinterpret_cast<char*>(elem->buffer + offset++), 1);
    } while (!elem->fs->eof());
    return true;
  }

  bool FileCache::commit() {
    bool flag = false;
    auto it = this->cache.begin();
    while (it != this->cache.end()) {
      auto elem = *it;
      if (elem->dirty && elem->buffer != nullptr) {
        elem->fs->seekp(std::fstream::beg);
        for (size_t i = 0; i < elem->size; i++) {
          elem->fs->write(reinterpret_cast<char*>(elem->buffer + i), 1);
        }
        flag = true;

        free(elem->name);
        free(elem->buffer);
        delete elem;
        it = this->cache.erase(it);
      } else it++;
    }
    return flag;
  }

  bool FileCache::write(size_t idx, size_t size, off_t offset) {
    if (idx >= this->cache.size() || offset < 0) return false;
    auto elem = this->cache[idx];
    if (elem->buffer == nullptr) {
      if (elem->size == 0) {
        elem->buffer = static_cast<uint8_t*>(malloc(size + offset));
        elem->size = size + offset;
      } else {
        elem->buffer = static_cast<uint8_t*>(malloc(elem->size));
      }
    }

    size_t endsize = offset + size;
    if (elem->size < endsize) {
      elem->buffer = static_cast<uint8_t*>(realloc(elem->buffer, endsize));
    }

    for (size_t idx = 0; idx < size; idx++) {
      std::cin.read(reinterpret_cast<char*>(elem->buffer + offset + idx), 1);
    }

    elem->dirty = true;

    return true;
  }

  uint8_t* FileCache::read(size_t idx, size_t size, off_t offset) {
    if (idx >= this->cache.size() || offset < 0) return nullptr;
    auto elem = this->cache[idx];
    if (elem->buffer == nullptr || elem->size < size || elem->size < size + offset) {
      return nullptr;
    }

    return &elem->buffer[offset];
  }

  CacheElem* FileCache::search(char* name) {
    for (auto elem : this->cache) {
      if (strcmp(elem->name, name) == 0) return elem;
    }
    return nullptr;
  }
}
