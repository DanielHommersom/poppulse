class_name AppInfo
extends RefCounted
## The game's public name in one place (US-37). Deliberately not "Pop It":
## that is the brand of the physical toy. Working title — run a trademark
## check before launch and change it here (+ project name, products, store).

const NAME := "Pop Pulse"
const TITLE := "POP PULSE"
const HASHTAG := "#PopPulse"

## Public pages: source in docs/ (index.html = privacy, terms/, support/), published
## from the repo danielhommersom.github.io, folder poppulse/ (copy after edits).
const WEBSITE_URL := "https://danielhommersom.github.io/poppulse/"
const PRIVACY_URL := "https://danielhommersom.github.io/poppulse/"
const TERMS_URL := "https://danielhommersom.github.io/poppulse/terms/"
const SUPPORT_URL := "https://danielhommersom.github.io/poppulse/support/"
## Numeric App Store id (App Store Connect ▸ App Information ▸ Apple ID).
## Share links (Tell a friend, result card) point to the App Store page.
const APP_STORE_ID := "6822425109"
const ANDROID_PACKAGE := "com.digitaldiamonds.poppulse"


## Store page for this platform (fallback: the website).
static func store_url() -> String:
	if OS.get_name() == "Android":
		return "https://play.google.com/store/apps/details?id=" + ANDROID_PACKAGE
	if APP_STORE_ID != "":
		return "https://apps.apple.com/app/id" + APP_STORE_ID
	return WEBSITE_URL
