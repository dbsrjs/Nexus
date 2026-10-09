#ifndef RUNNER_DESKTOP_SHELL_H_
#define RUNNER_DESKTOP_SHELL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>
#include <shellapi.h>

#include <memory>
#include <optional>
#include <string>

// 트레이 아이콘과 데스크톱 알림(«마지막» 단계). 앱 쪽 짝은
// lib/features/desktop/desktop_shell_io.dart 다.
//
// 패키지(tray_manager · local_notifier 등)를 들이지 않고 Shell_NotifyIcon 하나로
// 만든다 — 아이콘 · 메뉴 · 알림(풍선 → Windows 10 이상에서는 토스트로 보인다)이 모두
// 이 API 하나에 있고, 직접 만들 수 있으면 패키지를 들이지 않는다(CLAUDE.md §3-8).
//
// 알림 하나하나를 따로 기억하지 않는다 — 풍선은 하나씩만 떠 있고 새것이 옛것을
// 덮으므로, 누를 수 있는 것은 늘 마지막 알림이다.
class DesktopShell {
 public:
  DesktopShell(HWND window, flutter::BinaryMessenger* messenger);
  ~DesktopShell();

  DesktopShell(const DesktopShell&) = delete;
  DesktopShell& operator=(const DesktopShell&) = delete;

  // 창 프로시저가 가장 먼저 부른다. 이 클래스가 처리한 메시지면 값을 돌려준다.
  std::optional<LRESULT> HandleMessage(HWND hwnd, UINT message, WPARAM wparam,
                                       LPARAM lparam);

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  bool AddIcon();
  void RemoveIcon();
  bool Notify(const std::wstring& title, const std::wstring& body,
              const std::string& payload);
  void ShowMenu(POINT at);
  void ShowWindowFront();
  bool IsForeground() const;

  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  // LoadImage 로 만든 아이콘이라 소멸자에서 DestroyIcon 한다(LR_SHARED 가 아니다).
  HICON icon_ = nullptr;

  // 아이콘이 실제로 트레이에 올라가 있는가. 올라가지 못했으면(탐색기가 없는 셸 등)
  // 창을 닫을 때 숨기지 않고 정말 닫는다 — 숨기면 다시 꺼낼 길이 없다.
  bool icon_added_ = false;

  // 탐색기가 다시 뜨면 트레이가 비워진다. 그때 오는 방송 메시지 번호.
  UINT taskbar_created_ = 0;

  // 트레이 메뉴의 「종료」를 눌렀다. 이 뒤의 WM_CLOSE 는 숨기지 않고 정말 닫는다.
  bool quitting_ = false;

  // 마지막으로 띄운 알림을 누르면 앱에 돌려줄 값(갈 주소).
  std::string last_payload_;
};

#endif  // RUNNER_DESKTOP_SHELL_H_
