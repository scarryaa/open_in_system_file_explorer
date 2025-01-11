#include "flutter_window.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shellapi.h>

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  SetupMethodChannel();
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::SetupMethodChannel() {
  auto channel = std::make_unique<flutter::MethodChannel<>>(
      flutter_controller_->engine()->messenger(),
      "plugins.scar.lt/open_in_system_file_explorer",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler([](const auto &call, auto result) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Path argument is required");
      return;
    }

    auto path_it = arguments->find(flutter::EncodableValue("path"));
    if (path_it == arguments->end()) {
      result->Error("INVALID_ARGUMENTS", "Path argument is required");
      return;
    }

    std::string path = std::get<std::string>(path_it->second);

    if (call.method_name() == "openFile") {
      std::string command = "/select,\"" + path + "\"";
      ShellExecuteA(nullptr, "open", "explorer.exe", command.c_str(), nullptr,
                    SW_SHOWNORMAL);
      result->Success(flutter::EncodableValue(true));
    } else if (call.method_name() == "openDirectory") {
      ShellExecuteA(nullptr, "explore", path.c_str(), nullptr, nullptr,
                    SW_SHOWNORMAL);
      result->Success(flutter::EncodableValue(true));
    } else {
      result->NotImplemented();
    }
  });
}
