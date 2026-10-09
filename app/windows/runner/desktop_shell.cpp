#include "desktop_shell.h"

#include <flutter/standard_method_codec.h>
#include <strsafe.h>
#include <windowsx.h>

#include "resource.h"

namespace {

// 트레이 아이콘이 창에 보내는 메시지. WM_APP 위는 앱이 마음대로 쓰는 범위다.
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kTrayIconId = 1;

constexpr UINT kMenuOpen = 1;
constexpr UINT kMenuQuit = 2;

// 채널 이름은 앱 쪽(desktop_shell_io.dart)과 같아야 한다.
constexpr char kChannelName[] = "nexus/desktop";

std::wstring Utf8ToWide(const std::string& text) {
  if (text.empty()) {
    return std::wstring();
  }
  const int length = ::MultiByteToWideChar(
      CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0);
  if (length <= 0) {
    return std::wstring();
  }
  std::wstring wide(static_cast<size_t>(length), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                        wide.data(), length);
  return wide;
}

// 인자 맵에서 문자열 하나. 없거나 문자열이 아니면 빈 값 — 알림 하나가 잘못 왔다고
// 앱을 죽이지 않는다.
std::string StringArg(const flutter::EncodableMap& args, const char* key) {
  const auto found = args.find(flutter::EncodableValue(std::string(key)));
  if (found == args.end()) {
    return std::string();
  }
  const auto* value = std::get_if<std::string>(&found->second);
  return value ? *value : std::string();
}

NOTIFYICONDATAW BaseIconData(HWND window) {
  NOTIFYICONDATAW data{};
  data.cbSize = sizeof(data);
  data.hWnd = window;
  data.uID = kTrayIconId;
  return data;
}

}  // namespace

DesktopShell::DesktopShell(HWND window, flutter::BinaryMessenger* messenger)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannelName, &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });

  // 작업 표시줄 크기의 작은 아이콘. 실패해도 트레이 없이 뜰 뿐 앱은 돈다.
  icon_ = static_cast<HICON>(::LoadImageW(
      ::GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON,
      ::GetSystemMetrics(SM_CXSMICON), ::GetSystemMetrics(SM_CYSMICON),
      LR_DEFAULTCOLOR));

  // 탐색기가 죽었다 살아나면 트레이가 비워진다 — 그 방송을 받아 다시 올린다.
  // 이것이 없으면 탐색기 재시작 뒤 창을 닫은 사용자가 앱을 다시 꺼낼 수 없다.
  taskbar_created_ = ::RegisterWindowMessageW(L"TaskbarCreated");

  AddIcon();
}

DesktopShell::~DesktopShell() {
  // 엔진이 먼저 내려가므로 이 뒤로 앱에서 오는 호출을 받지 않는다.
  if (channel_) {
    channel_->SetMethodCallHandler(nullptr);
  }
  // 지우지 않으면 프로세스가 끝난 뒤에도 마우스를 올릴 때까지 유령 아이콘이 남는다.
  RemoveIcon();
  if (icon_) {
    ::DestroyIcon(icon_);
    icon_ = nullptr;
  }
}

bool DesktopShell::AddIcon() {
  if (icon_added_ || !icon_) {
    return icon_added_;
  }
  NOTIFYICONDATAW data = BaseIconData(window_);
  data.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP | NIF_SHOWTIP;
  data.uCallbackMessage = kTrayMessage;
  data.hIcon = icon_;
  ::StringCchCopyW(data.szTip, ARRAYSIZE(data.szTip), L"Nexus");
  if (!::Shell_NotifyIconW(NIM_ADD, &data)) {
    return false;
  }
  // 버전 4 — 클릭 · 메뉴 · 알림 클릭이 lParam 의 아래 워드로 구분돼 온다.
  data.uVersion = NOTIFYICON_VERSION_4;
  ::Shell_NotifyIconW(NIM_SETVERSION, &data);
  icon_added_ = true;
  return true;
}

void DesktopShell::RemoveIcon() {
  if (!icon_added_) {
    return;
  }
  NOTIFYICONDATAW data = BaseIconData(window_);
  ::Shell_NotifyIconW(NIM_DELETE, &data);
  icon_added_ = false;
}

std::optional<LRESULT> DesktopShell::HandleMessage(HWND hwnd, UINT message,
                                                   WPARAM wparam,
                                                   LPARAM lparam) {
  if (taskbar_created_ != 0 && message == taskbar_created_) {
    icon_added_ = false;
    AddIcon();
    return 0;
  }

  switch (message) {
    case WM_CLOSE:
      // 메신저는 창을 닫아도 알림을 받아야 한다 — 트레이로 숨긴다. 정말 끝내기는
      // 트레이 메뉴의 「종료」다. 트레이가 없으면(아이콘을 못 올렸으면) 그냥 닫는다.
      if (quitting_ || !icon_added_) {
        return std::nullopt;
      }
      ::ShowWindow(hwnd, SW_HIDE);
      return 0;

    case kTrayMessage:
      switch (LOWORD(lparam)) {
        case NIN_SELECT:
        case NIN_KEYSELECT:
          ShowWindowFront();
          return 0;
        case WM_CONTEXTMENU:
          ShowMenu(POINT{GET_X_LPARAM(wparam), GET_Y_LPARAM(wparam)});
          return 0;
        case NIN_BALLOONUSERCLICK:
          ShowWindowFront();
          if (!last_payload_.empty()) {
            channel_->InvokeMethod(
                "notificationClicked",
                std::make_unique<flutter::EncodableValue>(last_payload_));
          }
          return 0;
      }
      return 0;
  }
  return std::nullopt;
}

void DesktopShell::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();

  if (method == "available") {
    result->Success(flutter::EncodableValue(icon_added_));
    return;
  }
  if (method == "isForeground") {
    result->Success(flutter::EncodableValue(IsForeground()));
    return;
  }
  if (method == "focus") {
    ShowWindowFront();
    result->Success();
    return;
  }
  if (method == "notify") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Error("bad-args", "notify 는 맵을 받는다");
      return;
    }
    const bool shown = Notify(Utf8ToWide(StringArg(*args, "title")),
                              Utf8ToWide(StringArg(*args, "body")),
                              StringArg(*args, "payload"));
    result->Success(flutter::EncodableValue(shown));
    return;
  }
  result->NotImplemented();
}

bool DesktopShell::Notify(const std::wstring& title, const std::wstring& body,
                          const std::string& payload) {
  if (!icon_added_) {
    return false;
  }
  NOTIFYICONDATAW data = BaseIconData(window_);
  data.uFlags = NIF_INFO;
  // 길이를 넘으면 StringCch 가 잘라 끝을 0 으로 막는다(제목 63자 · 본문 255자).
  ::StringCchCopyW(data.szInfoTitle, ARRAYSIZE(data.szInfoTitle),
                   title.c_str());
  // 본문이 비면 풍선이 뜨지 않는다(빈 szInfo 는 「풍선 지우기」다).
  ::StringCchCopyW(data.szInfo, ARRAYSIZE(data.szInfo),
                   body.empty() ? L" " : body.c_str());
  data.dwInfoFlags = NIIF_NONE;
  if (!::Shell_NotifyIconW(NIM_MODIFY, &data)) {
    return false;
  }
  last_payload_ = payload;
  return true;
}

void DesktopShell::ShowMenu(POINT at) {
  HMENU menu = ::CreatePopupMenu();
  if (!menu) {
    return;
  }
  ::AppendMenuW(menu, MF_STRING, kMenuOpen, L"Nexus 열기");
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(menu, MF_STRING, kMenuQuit, L"종료");
  ::SetMenuDefaultItem(menu, kMenuOpen, FALSE);

  // 창을 앞으로 가져오지 않으면 메뉴 밖을 눌러도 메뉴가 닫히지 않는다(알려진 셸 동작).
  ::SetForegroundWindow(window_);
  const UINT picked = static_cast<UINT>(::TrackPopupMenuEx(
      menu, TPM_RETURNCMD | TPM_NONOTIFY | TPM_RIGHTBUTTON, at.x, at.y,
      window_, nullptr));
  ::PostMessageW(window_, WM_NULL, 0, 0);
  ::DestroyMenu(menu);

  if (picked == kMenuOpen) {
    ShowWindowFront();
  } else if (picked == kMenuQuit) {
    // 여기서 DestroyWindow 를 부르면 OnDestroy 가 이 객체를 지운 뒤 이 함수로 돌아온다.
    // 표시만 해 두고 닫기를 메시지로 보내, 지금 호출이 다 풀린 뒤에 닫히게 한다.
    quitting_ = true;
    ::PostMessageW(window_, WM_CLOSE, 0, 0);
  }
}

void DesktopShell::ShowWindowFront() {
  if (::IsIconic(window_)) {
    ::ShowWindow(window_, SW_RESTORE);
  } else {
    ::ShowWindow(window_, SW_SHOW);
  }
  ::SetForegroundWindow(window_);
}

bool DesktopShell::IsForeground() const {
  return ::IsWindowVisible(window_) && !::IsIconic(window_) &&
         ::GetForegroundWindow() == window_;
}
