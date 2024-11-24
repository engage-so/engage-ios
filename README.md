# Engage iOS SDK

[Engage](https://engage.so/) helps businesses deliver personalized customer messaging and marketing automation through email, SMS and in-app messaging. This iOS SDK makes it easy to identify customers, sync customer data (attributes, events and device tokens) to the Engage dashboard and send in-app messages to customers.

## Features

- Track device token
- Identify users
- Update user attributes
- Track user events

## Getting started

- [Create an Engage account](https://engage.so/) and set up an account to get your public API key.
- Learn about [connecting customer data](https://engage.so/docs/guides/connecting-user-data) to Engage.

## Installation

The SDK is available via SPM or Cocoapods.

### Swift Package Manager (SPM)

1. In Xcode, go to your project’s **Package Dependencies** section.
2. Click the **+** button to add a new package.
3. Enter the following URL:

```
https://github.com/engage-so/engage-ios.git
```

4. Choose the version you want to install, and add it to your project.

### CocoaPods

1. Add the Engage SDK to your `Podfile`:

```ruby
platform :ios, '13.0'

target 'YourAppTarget' do
    use_frameworks!

    pod 'Engage-swift', :git => 'https://github.com/engage-so/engage-ios.git', :tag => 'v1.0.0'
end
```

2. Install the dependencies by running:

```bash
pod install
```

#### Example of Dependency Declaration in `Package.swift`

If you are using Swift Package Manager programmatically in a `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/engage-so/engage-ios.git", from: "1.0.0")
]
```

## Initialization

Import `Engage` and initialize the SDK.

```swift
// ...
import Engage

@main
struct MainApp: App {
    init() {
        Engage.shared.initialise(publicKey: "public-api-key")
    }
    // ...
}
```

## Identify users

Engage uses your user's unique identifier (this is mostly the ID field of the users' table) for data tracking. **Identify** lets you link this ID to the user. With identify, you are able to supply more details about the user.

```swift
let properties = ["first_name": "Jane", "last_name": "Doe", "last_login": Date()]
Engage.shared.identify(uid: "user-id", properties: properties)
```

Engage supports the following standard attributes: `first_name`, `last_name`, `email`, `number` (customer's phone number) but you can use identify to add any customer attribute you want. `last_login` in the example above is an example.

When new users are identified, Engage assumes their signup date to be the current timestamp. You can change this by adding a `created_at` attribute.

```swift
let properties = ["first_name": "Jane", "last_name": "Doe", "created_at": "2021-01-04"]
Engage.shared.identify(uid: "user-id", properties: properties)
```

## Add attributes

To add more attributes to the user's profile, use the `addAttributes` method.

```swift
let attributes = ["plan": "Pro", "age": 14]
Engage.shared.addAttributes(properties: attributes, uid: "optional")
```

## Set device token

Engage integrates with [FCM](https://firebase.google.com/docs/cloud-messaging) to let you send push notifications to your users, either through broadcast or automation. However, to do this, you need to send the user's FCM registration token to Engage. The device registration token is a unique identifier that allows the device receive messages.

```swift
func onNewToken(token: String) {
    Engage.shared.setDeviceToken(deviceToken: token, uid: "optional")
}
```

## Track events

Track an event:

```swift
Engage.shared.track(event: "Login", uid: "optional")
```

Track an event with a value:

```swift
Engage.shared.track(event: "Clicked", value: "Login button", uid: "optional")
```

Track an event with properties:

```swift
let properties = ["type": "button", "counter": counter]
Engage.shared.track(event: "Clicked", value: properties, uid: "optional")
```

Engage sets the event date to the current timestamp but if you would like to set a different date, you can add a date as an argument in the `track` method.

```swift
Engage.shared.track(event: "Clicked", value: "Login button", date: Date(), uid: "optional")
```
