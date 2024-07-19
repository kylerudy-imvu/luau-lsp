#include <stdio.h>
#include <string>
#include <memory>
#include <algorithm>

#include <emscripten/emscripten.h>
#include <emscripten/bind.h>
#include <emscripten/val.h>
#include "include/LSP/ServerIOWasm.hpp"
#include "include/LSP/LanguageServer.hpp"
#include "include/LSP/Client.hpp"

using emscripten::val;

// probably a better way to do this
std::vector<std::filesystem::path> translatePathVec(const std::vector<std::string> & inputs) {
    std::vector<std::filesystem::path> output(inputs.begin(), inputs.end());
    return output;
}

std::shared_ptr<LanguageServer> createWasmLanguageServer(const val & output, const val & definitionsFiles, const val & documentationFiles) {
    auto io = std::make_shared<ServerIOWasm>(output);
    // there has to be a better way to do this
    auto defs = emscripten::vecFromJSArray<std::string>(definitionsFiles);
    auto docs = emscripten::vecFromJSArray<std::string>(documentationFiles);
    auto defsPtr = std::make_shared<std::vector<std::filesystem::path>>(translatePathVec(defs));
    auto client = std::make_shared<Client>(io, defsPtr, translatePathVec(docs));
    auto server = std::make_shared<LanguageServer>(client, std::nullopt);
    return server;
}

EMSCRIPTEN_BINDINGS(languageServerBindings) {
    emscripten::function("createWasmLanguageServer", &createWasmLanguageServer, emscripten::return_value_policy::take_ownership());
    
    emscripten::class_<LanguageServer>("LanguageServer")
            .smart_ptr<std::shared_ptr<LanguageServer>>("LanguageServer")
            .function("processInput", &LanguageServer::processInput);
}