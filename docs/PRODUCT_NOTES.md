# Product and research reference

## Discovery, delivery and one-app trials — 28 November clarification

Owner prioritises people finding the app and asks which sites combine hosting,
payment and automated access. Latest recommendation after clarifying discovery:
**Samsung Galaxy Store is a first-store candidate** for the no-sign-up/annual-fee,
mobile-marketplace preference, subject to commercial-seller approval and a finished
review-ready app. Google Play remains the main broader Android target; Apple
follows native parity. This refines the earlier Samsung-as-extra recommendation.
If store approval delays launch, Payhip/Gumroad can deliver an early direct APK.
Working direction is now Samsung first, subject to commercial-seller eligibility
and review; no developer/seller account has been registered. Samsung sales do not
create Payhip sales or a Gumroad account balance: their discovery thresholds
concern transactions on their own platforms. Those storefronts are optional,
not a required next stage after earning a certain amount on Samsung.

A Samsung-only launch can handle discovery, delivery, updates and purchases with
Samsung IAP integration. Keep the customer journey in that channel; do not use its
listing simply to redirect buyers elsewhere. Samsung's metadata rules prohibit
promotion of other app stores/mobile platforms.
[Samsung distribution guide](https://developer.samsung.com/galaxy-store/distribution-guide.html?lang=en).
Expand only for a concrete audience need: other Android brands through Play or
iPhone users through Apple; direct/desktop sales if requested later. Galaxy Store
runs on Samsung Android phones/tablets, so Samsung alone will not cover those
other device audiences. A marketplace presence is not a guarantee of downloads.

Payhip and Gumroad are general digital-product storefronts, not specialist phone
app stores. Their own discovery is conditional: Payhip requires at least US$10 in
genuine sales plus account/product approval; Gumroad currently requires a US$100
balance from genuine sales, risk verification and product eligibility. Neither
is a dependable way to bootstrap the first customers. A hosted sales page is
useful for payment/downloads but does not guarantee an audience.
[Payhip Marketplace](https://help.payhip.com/article/307-marketplace),
[Gumroad Discover](https://gumroad.com/help/article/79-gumroad-discover).

Samsung's official FAQ confirms no sign-up or annual publishing fee and states
Galaxy Store runs on Samsung Android phones/tablets. It is genuine app browsing/
search with checkout support, but does not reach all Android makes. It uses its
own commercial verification and review; the Play Console closed-test gate is
separate. Review the final build/billing/signing/privacy/AI-reviewer access before
submission; current private test APK is not a public-store release.
[Samsung FAQ](https://developer.samsung.com/galaxy-store/faq.html),
[seller setup](https://developer.samsung.com/galaxy-store/prepare.html),
[distribution requirements](https://developer.samsung.com/galaxy-store/distribution-guide.html?lang=en).
Other actual mobile marketplaces include
[Huawei AppGallery](https://developer.huawei.com/consumer/en/doc/app/50104-overview/)
and [Aptoide](https://en.aptoide.com/). Target-user demand, current compatibility
and billing would need validation; no evidence from this research establishes
their Australian renovation-app conversion or return on integration effort.

Practical discovery experiment, no paid advertising or messages authorised:
create a short real kitchen before/after/refinement demo with an honest BYO-key
explanation; use searchable store title/screenshots; invite a small set of local
DIY renovators and real-estate agents; seek permission before community promotion;
use short video/search traffic to a single consistent app/store page. BYO setup
still needs a clear walkthrough. Measure actual visits, installs, activations,
completed first designs and voluntary feedback before adding more stores. A
marketplace listing makes discovery possible; it does not supply guaranteed users.

Store-managed route: Google/Apple/Samsung host platform builds and provide
checkout, purchase history and entitlement APIs. Integrate the relevant billing/
restore/verification code; no manually emailed seller licence is normally needed.
Store-provided subscription trial offers can renew into paid subscriptions, so
do not describe them as no-card/no-renewal tester access. A free limited app with
an explicit one-off upgrade is another design; its evaluation controls still
need implementation. Google also documents non-auto-renewing prepaid plans;
Apple describes non-subscription time trials with a zero-priced trial IAP.
[Play subscriptions](https://developer.android.com/google/play/billing/subscriptions),
[Play purchase verification](https://developer.android.com/google/play/billing/security),
[Apple subscriptions](https://developer.apple.com/app-store/subscriptions/),
[Apple review/payment/trial rules](https://developer.apple.com/app-store/review/guidelines/),
[Samsung IAP](https://developer.samsung.com/iap/overview.html).
Use each store's permitted purchase mechanism for that build; an external licence
screen is not a universal substitute for store billing, especially Apple's 3.1.1.
The earlier private/public signed-licence proposal is an option for independent
activation, not a requirement to run our own key issuer on every store.

Direct storefront route: Payhip hosts software files and download pages and
supports automatic delivery of either generated software codes or a list supplied
by the seller. No owner needs to be awake to email codes individually. Its current
list limit is 10,000 short keys/100 characters each; these are redemption codes,
not necessarily a full signed entitlement document. Its documentation warns that
sales can continue without delivering a key if a supplied list runs out; use
automatic generation or constrain inventory. Expiry/room limits/recovery remain
our application/licensing-service responsibility. Keep its product secret off
public APKs and use a supported server/public-app integration.
[Payhip delivery](https://payhip.com/features/sell-digital-downloads),
[Payhip licence options](https://help.payhip.com/article/317-software-license-keys-new).
Gumroad automatically issues software keys in receipt/download pages but does
not import a seller's own list of keys. Its API exposes purchase state; app
enforcement remains ours. [Gumroad licensing](https://gumroad.com/help/article/76-license-keys).
Both can host the current approximately 86 MB Android package; published free
Gumroad file allowance is 250 MB and Payhip's per-file allowance is 5 GB.
[Gumroad limits](https://gumroad.com/help/article/289-file-size-limits-on-gumroad).

Recommend one installed app per platform: trial/free state > purchase/redeem >
Standard state, retaining all projects/photos/choices. Two storefront offers can
deliver the same direct APK with different entitlements; they do not require two
app identities. Android and iOS remain different builds of the shared source.
Multiple stores are possible later but need channel billing, update/signing and
purchase-restore acceptance; do not assume one store's receipt unlocks another.

Distinguish a permanently free sample/viewer from an expiring evaluation. The
sample can work without activation. A timed/room-limited trial still needs a
remembered eligibility/expiry record even if it is a separate free download;
separating APKs does not solve reinstall abuse. Store offer eligibility or a
verified direct-trial record provides the appropriate foundation. Subscription
free trials may convert into a charge; beta invitations can stay no-card/no-charge.
BYO API costs remain separate from software download/trial access.

This is research/planning only. No new billing library, app restriction, store
listing, licence generation, payment service, separate free APK or deployment.

## Signed access, hosted checkout and repeat trials — 28 November refinement

Owner accepts activation-code direction, wants hosted transaction handling with
minimal customer data, optional marketing email later, and free time/room-limited
test access with controls against reinstalling repeatedly. The duration, limits,
checkout provider and service hosting are still proposals; no paywall is shipped.

Use a small licence service, not a required separate master phone app. Hosted
checkout handles card entry and payment. A verified purchase event/lookup creates
our access record; a tester invitation can create a free access record without
any card. An opaque activation code is redeemed over HTTPS for a signed licence.
The private **licence signing** key stays only on the service; the distributed
app holds its verification public key. This is signature verification, not public-
key decryption. It is separate from Android package signing and customer AI keys.
Signed fields can include licence ID, product/app audience, trial/paid plan,
issued/not-before/expiry timestamps, permitted project/room creations, activation
binding, policy version and signing-key ID. Do not put unnecessary customer PII
inside a readable signed token. [JWS](https://www.rfc-editor.org/rfc/rfc7515),
[expiry claims](https://www.rfc-editor.org/rfc/rfc7519).

The app verifies signature, issuer/audience/device binding and time/limits. Online
activation/renewal checks authoritative time and refund/revocation status; signed
tokens expire and have bounded offline grace, including clock-rollback handling.
Renewal returns a new signed entitlement. Keep creation counters on the service
across reinstalls and project deletion; deletion must not replenish a cumulative
trial allowance. A phone-local clock/counter or a signed token alone cannot prove
one trial per person, enforce revocation instantly offline or prevent modified
clients. Retain access to viewing/exporting saved work after trial expiry.

Suggested beta: individually issued **30-day tester access**, one project/three
room creations, no payment card, with feedback/recovery options. This is a longer
test invitation than the proposed public seven-day evaluation and covers a later
Play closed-test period if applicable. Verify email using a one-time link/code;
recover the same server-side trial/expiry after reinstall. Separate testers from
paid licences and BYO API credentials. Free app access does not fund provider AI;
the existing offline sample remains usable without an API key. Invitation-only
issuance, per-email trial history, resend/rate limits and capped activations are
proportionate first controls. New emails/multiple devices can still evade a
per-email trial; do not claim perfect prevention or deny legitimate recovery.

Do not request IMEI/serial permissions or add covert hardware fingerprinting.
Android restricts non-resettable hardware IDs to privileged/carrier/device-owner
use cases and recommends appropriately scoped identifiers.
[Android guidance](https://developer.android.com/identity/user-data-ids).
Ordinary installation IDs are resettable; optional scoped ANDROID_ID has device/
user/signing-key and reset limits and is not proof of a unique person. No such ID
is collected by the current app. [Android ID reference](https://developer.android.com/reference/android/provider/Settings.Secure.html#ANDROID_ID).
Play Integrity device recall can retain trial-abuse flags across reinstall/reset,
but is currently an eligibility-limited beta requiring production Play Integrity/
Play Billing usage and a Play-licensed account. It is not a ready control for a
new direct-download beta. Recheck before any later integration.
[Official device recall prerequisites](https://developer.android.com/google/play/integrity/device-recall).

Use hosted checkout/merchant-of-record handling so RenoVision never receives or
stores card numbers/CVV. The payment company still holds billing/transaction
information; the seller may see order/contact details in its dashboard. Our
allow-listed licensing record should keep only necessary purchase ID, product,
access dates/status and recovery email or minimal verified identity reference.
Do not persist entire payment webhook/API responses, which may contain extra
customer fields. Owner need not host photo projects or AI keys for licensing.
[Gumroad customer checkout](https://gumroad.com/help/article/282-how-do-purchases-work-for-my-customers),
[Gumroad payment processing](https://gumroad.com/help/article/260-your-payout-settings-page).

Marketing permission is separate from purchase, activation and testing. Offer an
optional unticked email-updates checkbox, retain consent scope/time and honour
withdrawal. Do not automatically add every buyer/tester to promotional mail;
necessary receipt/recovery messages should remain factual. The customer email is
still personal data even if encrypted. ACMA recommends express consent, recording
it, sender identity and a working unsubscribe path.
[ACMA marketing consent](https://www.acma.gov.au/avoid-sending-spam).

Implementation sequence: provider-neutral entitlement model and mock-service
tests; signed verification/activation/recovery UI; server/admin invitation and
purchase verification; hosted checkout adapter; end-to-end expiry/reinstall/
refund/device-change checks. Keep signing/checkout secrets off source, logs and
APK. No account, key generation, backend deployment, email or payment was sent.

## Low-overhead selling, portable access and staging — 28 November follow-up

Confirmed owner direction: a modest, personally useful BYO renovation tool;
affordable pricing, no paid seller subscription/sign-up fee, preferably a cut of
actual sales, and freedom to change platform or pricing later. Keep the scope
manageable. Price, sales platform and paid access model remain unselected.

Current candidate plans, checked against official pages:

- Gumroad: no monthly platform fee; direct sales 10% + US$0.50, Discover 30%;
  emailed software keys and sales/customer CSV export. Existing licensing/API
  integration still has to enforce access in RenoVision.
  [Pricing](https://gumroad.com/pricing),
  [software keys](https://gumroad.com/help/article/76-license-keys),
  [sales export](https://gumroad.com/help/article/268-customer-dashboard).
- Payhip Free Forever: no monthly fee, 5% platform fee **plus** Stripe/PayPal
  processing. Includes a storefront, software-key options and customer CSV export.
  Its product-secret licence API needs a secure server or the vendor's supported
  public-app alternative; never embed that secret in the distributed APK.
  [Pricing](https://payhip.com/pricing),
  [licensing](https://help.payhip.com/article/317-software-license-keys-new),
  [export](https://help.payhip.com/article/83-export-customers).
- Paddle pay-as-you-go: no monthly platform fee; advertised 5% + US$0.50 per
  checkout, with account approval/integration needed. Its page asks sellers of
  products under US$10 to contact it about pricing. A possible later software-
  billing option, not a selected or opened account.
  [Pricing/migration statement](https://www.paddle.com/pricing).

Free seller plans still require account/identity/payout setup. A sales page can
use the platform's hosted address at first; no paid custom-domain commitment is
needed just to test demand. Avoid representing all checkout fees as a single
percentage or suggesting a paid storefront supplies a ready-made app paywall.

Proposed portability: stable RenoVision licence/customer identifiers with a
separate mapping to each checkout's purchase IDs; an independent access record
containing product, expiry/entitlements and refund status; isolated provider
adapters and recoverable/exportable records. Honour existing purchase promises
when adding new prices/plans. CSV export does not transfer stored payment methods
or recurring mandates automatically; provider migration/customer re-authorisation
may be required. A one-off unlock or explicitly renewed pass is simpler to move.
App projects/images stay local and portable; the seller's customer list is not a
cloud copy of those projects. No such licensing service has been implemented.

Recommended customer flow: Buy > receive licence code by email > Activate app >
periodic validation with a bounded offline grace period. Add Recover purchase /
Move to another device; optional email one-time-code or magic-link verification
can support recovery. Email addresses and public IDs alone are not proof of
purchase or identity. Codes are credentials, separate from AI API keys; store
activation/session secrets securely and never include them in project exports.
No full username/password system is required for this initial flow. The existing
API-key vault and TesterAllowance are not purchased software entitlements.

If passwords are added later, use a supported identity service with salted
adaptive password hashes rather than reversible password encryption or a custom
password database. [OWASP password storage](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).
Activation/expiry/recovery, licensing hosting and email delivery remain work;
free-tier services may suit a small beta but their limits/costs must be verified
before selection. No seller/auth/hosting account was created or deployed.

Owner also proposes real-estate room staging. Keep it in the shared app as a
dedicated task, not a separate product initially. Existing room photos/history/
comparison/export provide foundations; **no dedicated staging mode is shipped**.
Proposed first scope:

1. Property project > room photos > Stage this room; empty-room furnishing first.
2. Add movable furniture, rugs/art/accessories within the real room. Preserve the
   actual walls/openings, floor, fixed fittings, outside view, proportions and
   camera position. Do not apply whole-room renovation replacement defaults.
3. Compare with the immutable source and require agent review of architectural
   drift/hidden defects before export. Existing AI precision is prompt guidance,
   so it cannot guarantee all these constraints automatically.
4. Label output Virtually staged / furniture added digitally; retain the original
   alongside it. Offer a separate, clearly labelled Renovation concept for future
   finishes, rather than treating imagined work as a current-property photograph.
5. Later evaluate batch photos, shared project looks, agent branding/export sizes
   and agency seats only after real agent feedback. No new high-priced tier yet.

Australian listing requirements depend on the jurisdiction/platform. NSW's
official guidance says property images must truthfully represent the property
and must not hide undesirable characteristics. Labels alone do not cure a
misleading alteration. Verify the target market/portal and commercial-use terms
before marketing a listing-ready workflow; do not claim regulatory compliance
from a prompt. [NSW property advertising guidance](https://www.nsw.gov.au/housing-and-construction/property-professionals/working-as-an-agent/advertising-guidelines).

## Distribution and BYO-key pricing — researched 28 November 2026

Owner wants a modest paid launch, alternatives to Play's tester recruitment,
and time/usage-limited evaluation. These are **researched options and proposed
prices**, not selected products or implemented payment/trial controls. Private
APK 1.0.20, owner projects and provider connections are unchanged.

| Distribution route | Current position and tradeoff |
| --- | --- |
| Direct signed APK + website checkout | No Play production-test gate. Users allow installation from the chosen source; we supply download/update/support. Payment onboarding and Android verification are separate. Small invited beta candidate, with less discovery and installation trust than a store. |
| Hosted HTTPS web app | No store closed test. Shared Flutter web source exists; public hosting, mobile camera/storage and project portability need acceptance. Current localhost is not a public service. |
| Samsung Galaxy Store | Own commercial-seller verification/app certification, including free apps; not Google's 12-tester gate. Samsung audience. Samsung Checkout retains 20% of net app/IAP proceeds and 15% for subscriptions, before customary deductions/custom agreements. |
| Google Play | New personal accounts created after 13 November 2023 still need 12 testers continuously opted in for 14 days, then production-access review. Internal distribution exists before production access. Keep as a later broad-reach route. |

Sources: [Android distribution](https://developer.android.com/distribute/marketing-tools/alternative-distribution),
[Play testing](https://support.google.com/googleplay/android-developer/answer/14151465),
[Samsung seller setup](https://developer.samsung.com/galaxy-store/prepare.html),
[Samsung revenue share](https://developer.samsung.com/sdp/news/en/2025/03/13/new-revenue-share-model-for-galaxy-store).

Direct APK is not permanently registration-free. Current
[Android guidance](https://developer.android.com/developer-verification/guides/distributor-resources)
says verification began in selected stores/regions on 30 September 2026 and
expands globally across sources in 2027; its latest timeline starts participating
stores in January and other stores by March. Limited distribution is up to 20
devices; unregistered installs have a separate advanced flow. Full-distribution
console setup has identity checks and a US$25 fee:
[official console guide](https://developer.android.com/developer-verification/guides/pdf-guides/adc-guide.pdf).
Recheck the exact Australian install path before public sale. Amazon's Android-
phone Appstore ended support on 20 August 2025; Fire devices are separate.
[Amazon announcement](https://developer.amazon.com/apps-and-games/blogs/2025/02/upcoming-changes-to-amazon-appstore-for-android-devices-and-coins-program).

| Comparison | Published offer checked; not an Australian Android checkout quote |
| --- | --- |
| DecAI | US iOS description: US$6.99/week, US$59.99/year or US$129.99 lifetime. Web separately advertises generation quotas/credit packs. [US iOS](https://apps.apple.com/us/app/ai-home-design-interior-decai/id6502747597), [web](https://decai.ai/). |
| Remodel AI | US iOS catalogue includes monthly US$6.99–9.99 and yearly US$39.99–89.99 plus weekly offers; multiple entries do not establish the offer shown to a particular buyer. FAQ: limited trial renders then subscription. [US iOS](https://apps.apple.com/us/app/remodel-ai-home-design/id6446040791), [FAQ](https://remodelai.app/faqs/). |
| Renovate AI | Website yearly promotion: $5/$10/$33 per month equivalent, billed yearly, with differing usage levels. Actual currency, total, tax and Android offer need checkout confirmation. [Pricing](https://studio.renovateai.app/pricing). |
| EasyRender | Explicit BYO fal.ai key; advertised $6.99/month, $59/year, $159 one-time, plus direct provider bills. Website dollar currency not independently confirmed at checkout. Evidence of an existing flat tool fee + BYO model, not tested success/quality. [Official site](https://easyrender.app/). |
| RoomScape AI | Appostar UK describes direct-provider BYO-key Chrome extension with rooms/history/compare; in testing and listing pending. Close workflow, not evidence of released adoption/revenue. [Official page](https://www.appostar.co.uk/roomscape.html). |

Play developer listings identify DecAI / COOL SUMMER LIMITED in Hong Kong,
Renovate AI / TRIAL AND ERROR INC in Boston, US, and Remodel AI / ReImage AI Inc
in Nevada, US. Publisher addresses do not establish founders' nationality,
customer locations, model training data or processing location.
[DecAI](https://play.google.com/store/apps/details?hl=en_US&id=ai.interior.design.home.renovation.app),
[Renovate](https://play.google.com/store/apps/details?hl=en_CA&id=app.renovateai),
[Remodel](https://play.google.com/store/apps/details?id=ai.reimage.remodel).
Indie BYO room redesign also exists: this
[re-do.ai creator's Reddit post](https://www.reddit.com/r/vibecoding/comments/1q1v2cc/i_created_redoai_to_reimagine_your_house_and/)
advertises two credits or a personal key. It is a creator claim, not verified
revenue/geography. Reddit can provide feedback/recruitment; it is not app
distribution, checkout or entitlement infrastructure. No outreach was sent.

Proposed simple evaluation: seven free days, one project/two rooms, starting on
first real project use. Then choose **one** paid experiment: A$9.99 once for the
current major-version Standard BYO tools, or A$4.99 for a 90-day design pass
with explicit renewal/no automatic recurring charge. Owner has not approved
these prices/limits. Charge for tools/workflow; user pays their API provider
separately. No normal AI subscription/login or app licence implies API credit.
Do not add duplicate per-image charges as though we supplied their BYO usage.
Nontechnical key setup is a real adoption hurdle; keep the offline sample.

On expiry, retain originals, designs, viewing and backup/export; disable new
paid work and offer renewal/unlock. Do not blur/delete/confiscate saved results.
Room/time limits suit evaluation; future owner-funded AI needs separately capped
credits. Avoid many tiers and $1 micropayments initially because fixed checkout
fees/support weigh heavily on tiny payments. All prices are unvalidated proposals.

Needed implementation: software entitlements separate from AI keys/TesterAllowance;
redeem/restore activation, device policy, authoritative expiry, bounded offline
grace, refund/revocation handling and checks across setup/workspace/camera/polish.
An emailed activation licence can avoid mandatory app accounts. Minimal licensing
data can be hosted while photos still go directly to providers. Local-clock or
reinstall counters alone are weak controls; no licensing scheme is tamper-proof.

Gumroad candidate: direct-link fee 10% + US$0.50, Discover 30%, no monthly platform
fee. Software keys/purchase/subscription status are supported; enforcement remains
our implementation. Seller identity/payout onboarding is still needed.
[Pricing](https://gumroad.com/pricing),
[licensing API](https://gumroad.com/help/article/76-license-keys).
Keep direct and store checkout compliant with their own channel/regional rules:
[Play payments](https://support.google.com/googleplay/android-developer/answer/9858738),
[current fee programmes](https://support.google.com/googleplay/android-developer/answer/112622).
Do not start new Lemon Squeezy onboarding: its official docs say new sign-ups are
closed and the service winds down 31 March 2027.
[Official FAQ](https://docs.lemonsqueezy.com/migration/faq).

Next decision: one-off unlock versus expiring pass, trial limits and checkout/
hosting/support choices. Before paid beta, finish production signing/update path,
privacy/support destinations and real feedback delivery. Demonstrate an honest
kitchen before/after/refinement and saved-project workflow to invited Android DIY
renovators comfortable with API keys. Community outreach requires checking each
group's promotion rules; early genuine users can later help meet Play testing.
No account, payment, website, deployment, public post or customer service activated.

## Per-result AI cost estimates — 23 November

The owner requested costs beside analysis and generated images, rather than only
the Settings image total. Results now retain numeric provider usage and show model,
input/output tokens and an approximate request cost where the billing inputs are
known. Analysis input includes text and photos; output is the analysis response.
Image estimates include the returned text/image input split and image output.

Standard synchronous USD rates checked against official OpenAI model pages on
23 November 2026, per million tokens (input / cached input / output):

- [GPT-6 Luna](https://developers.openai.com/api/docs/models/gpt-6-luna): $0.10 / $0.01 / $0.50.
- [GPT-4.1 mini](https://developers.openai.com/api/docs/models/gpt-4.1-mini): $0.40 / $0.10 / $1.60.
- [GPT-4o mini](https://developers.openai.com/api/docs/models/gpt-4o-mini): $0.15 / $0.075 / $0.60.

The existing supported GPT Image 2.6 Sunburst/Flare calculation uses $5 text input,
$8 image input and $30 output per million tokens; see the
[image generation guide](https://developers.openai.com/api/docs/guides/image-generation)
and [pricing reference](https://developers.openai.com/api/docs/pricing). Incomplete
modality counts or cached image input remain unpriced, rather than applying an
incorrect formula. Unknown analysis models and nonstandard tiers also stay unpriced.

Gemini usage is retained but dollar estimates are not supplied until its returned
billable usage can be mapped reliably to the selected model's
[official pricing](https://ai.google.dev/gemini-api/docs/pricing). Missing old usage
cannot be reconstructed from an image alone. Settings continues to track image
costs only, deduplicated by provider request ID; analysis costs are shown per result.
These are dated estimates, not invoices, account balances or enforceable spending
caps. Taxes, exchange rates, discounts and failed/interrupted requests are outside
the tracked totals. No real provider request or owner key was used for verification.

## Language decision — 23 November

The owner first considered translated UI and AI text, then chose **English for
now** because they cannot personally assess foreign-language quality. This latest
choice supersedes the provisional rollout. Retain AU/NZ/UK/US English terminology;
do not translate existing project names, notes, prompts or version history.

Optional automatic translation could avoid hand-authoring every language pack,
but it still requires integrating the app's labels/messages and testing the UI.
It does not guarantee accurate renovation terms or remove the need for feedback
from users who understand the target language. Keep English source/fallback and a
clear option to return to English in any future implementation.

- **Phone app candidate:** Google's [ML Kit on-device translation](https://developers.google.com/ml-kit/language/translation)
  supports Android/iOS and more than 50 languages. Download/manage language models,
  then translate text on-device. Google describes it as suitable for casual/simple
  translation and recommends evaluation for the particular use case. Its Android
  integration translates supplied strings; it does not automatically rewrite a
  whole Flutter interface. [Android integration](https://developers.google.com/ml-kit/language/translation/android).
- **External user option:** Google Translate's [Tap to Translate](https://support.google.com/translate/answer/6350658?hl=en&co=GENIE.Platform%3DAndroid)
  translates copied text from another Android app. It does not translate every
  control or image in place and is not an embedded RenoVision translation feature.
- **Browser limitation:** a Chrome extension is not an Android-app integration.
  Flutter web uses graphics renderers, so ordinary website translation should not
  be relied on for complete interface coverage. This is our implementation inference
  from [Flutter's web architecture](https://docs.flutter.dev/platform-integration/web).
- **Cloud alternative:** [Google Cloud Translation](https://docs.cloud.google.com/translate/docs/setup)
  needs a configured Cloud project, authentication and billing. It is an optional
  future service, not an account or expense enabled in the current app.

No translation code or dependency was installed. The broader feature list is
consolidated in CODEX_NEXT_STEPS.md; do not treat old historical unchecked rows as
proof that recently completed controls are absent.

## Saving, scope and reusable project looks — current correction pass

Save and plaintext backup held the same project contents, so their separate normal
actions were confusing. Keep Save project and Save project as; the latter can make
an extra snapshot using another filename. Keep password export only in Advanced,
with accurate scope: it encrypts that exported file, not local data, existing plain
copies or a device. Opening older plain/protected files remains compatible.

Selecting a generated/saved result means refine that image by default. Show one
update field, exclude the original broader brief and clear the completed correction
on its newly saved result. Its historical prompt/recipe remains. Full/Partial are
explicit wider-renovation choices; Partial can resemble Full if all items or a
whole-room written request are included. Precision is prompt-guided, not an enforced
pixel mask; compare the actual output for unintended changes.

Project memory is reuse, not model training. The app already reuses matching room
observations across changed design choices. The new optional room-look picker copies
saved style/palette, preferring approved recipes; it never substitutes another room's
facts, photos, dimensions or instructions. New rooms retain independent analysis.

Splashback grout/edges can fragment colour-based tap selection. A reviewed full
four-corner outline covers the chosen plane including gaps. Add separate surfaces
for return walls. Directional/all-side growth is explicit and undoable; opacity
changes finish strength. Persistent expansion/scroll state prevents slider resets.

Real file round trips passed in Windows and new OneDrive Renos test folders using
generated fixture photos. Cloud sync and physical system-picker behaviour remain
separate platform acceptance; existing user files were not modified or deleted.

## Current decisions — 23 November

Provider keys now persist without an app account: encrypted browser-local vault
on web, secure device storage on Android. Browser origin/profile still matters;
clearing site data removes browser keys. No credentials are exported with projects.
The visible Autosave switch keeps device edits; a linked reusable browser file
also updates while connected. Backups are optional fixed snapshots of the same
project contents. Restore makes a copy; additive room import preserves separate
rooms instead of reconciling same-room edits. Archive/delete remains recoverable.

Whole-room concepts and focused selected-image updates are distinct operations.
Paint polishing sends the approximate finish guide with its clean source view,
excluding the original broad redesign. Stronger multiple-concept directions ask
for different material/cabinet/fitting schemes within the chosen palette. Real
provider comparison is still needed; no claim of ten-times-better output.

Optional sourced research is now a separate confirmed direct-OpenAI text request.
It does not send room photos or run automatically. Reviewed dated notes may inform
new concepts; precision excludes them. The old ChatGPT kitchen transcript/tool
history remains unavailable, so do not infer that it used web research.

Image-only usage estimates now retain returned tokens and use dated known USD
rates; unknown model/pricing remains unpriced. The manual image budget excludes
analysis, research, failed requests and tax/FX, and is not provider credit.
See [OpenAI pricing](https://developers.openai.com/api/docs/pricing) and
[web-search tool documentation](https://developers.openai.com/api/docs/guides/tools-web-search).
WebCrypto key storage follows browser structured-clone support, not a claim that
same-origin app code cannot use it: [WebCrypto specification](https://www.w3.org/TR/webcrypto/).

Imported tile textures and reviewed plane projection improve local previews.
Automatic semantic wall detection, enforced edit masks, product measurements,
tracked moving-room AR and a complete billing ledger remain future work.
No hosting/support address exists yet. Hosted tester credits and actual feedback/
report delivery need those services and an owner-approved budget; no deployment,
account signup or spending was performed. Older dated notes below are historical.

## Saving and design-quality regroup — 22 November

Use Save project for the working document. Backup exports the same contents as a
fixed snapshot and remains optional; duplicate creates a separate in-app branch.
Restore imports a separate copy. No merge is implemented. Browser credentials
remain memory-only across app navigation and are cleared on page reload; Android
vault credentials and all provider settings stay outside project exports.

The actual latest exported kitchen image updates surfaces/flooring, declutters,
removes the telephone and coordinates appliances, but retains a dated extractor
silhouette and a fairly uniform beige material treatment. The filename indicates
Sunburst 2.6 Medium; a weaker model is not established as the cause. A controlled
same-photo/brief/model comparison is needed, including High quality and the richer
current design plan. APK/browser differences may include build, choices or source
image; platform alone has not been shown to change provider quality.

The latest owner project file was empty despite reported success. A recovered
older Office/Kitchen project is preserved separately and is not the latest test.
Fresh testing must create a separate project without deleting any previous work.
The full ChatGPT web kitchen transcript was not found locally; supplied excerpts
do not establish which tools that conversation used.

Online research is a possible separate source of dated style/product references;
current generation does not search automatically or verify appliances against a
live catalogue. Cost per request/room could be estimated from returned usage and
dated model rates. The app does not currently track provider balance or dollars
remaining. These remain future work, not hidden background behaviour.

## Design proposal enhancement — 22 November

The preferred kitchen/idea board was created in a ChatGPT web conversation, not
through RenoVision. Keep that provenance explicit; its precise model/settings
and full multi-turn transcript are unavailable. Attractive framing, lighting,
staging and broader scene changes contribute to its appeal as well as rendering.

This batch improves the existing analysis-to-design workflow, without replacing
it with a conversational API or adding automatic paid analysis/critique. Analysis
now prepares one specific material/lighting/styling proposal within Full/Partial/
Precise scope. New current proposals default on for normal designs. Changed input
excludes a stale proposal and uses current choices plus matching photo observations;
it does not block generation or require another analysis just to change palette.
Precise corrections exclude broad proposals. Multiple concepts may reinterpret
suggestions but cannot override explicit materials, Keep, palette/style or scope.

Direct connections still use the existing image-edit API, with user-selected
model/quality. High quality is a useful controlled comparison, not proof of a more
creative scheme. Real output quality remains to be measured on the same original
photo/brief. Earlier generated versions and recipes are not rewritten.

Proposal composition avoids duplicating generic design guidance. It reserves
room for concept directions and may use a labelled excerpt of optional photo
observations while keeping the full saved analysis, written requirements and
edited proposal intact. Existing request-length guards still apply to very long
written briefs. This corrects the concrete case where a detailed kitchen proposal
plus three alternatives exceeded the existing limit before sending.

## Sample replay and tester access — 22 November

Owner explicitly authorised kitchen before/after images for inclusion in the app.
Use the historical saved-project pair and recorded brief, plus the supplied later
idea board; the board uses another viewpoint and its unavailable original chat
must not be replaced by an invented exact transcript. Bundle sanitised copies and
label the replay as offline. A separate practice project supports genuine tool,
save/reopen and export testing without an AI account, leaving customer work intact.

Owner proposes approximately $1 per tester. Prepare limited invitation access,
keeping the provider key on a server and attempts/expiry under server control.
Currency, hosting, funding and measured per-model cost remain decisions before
activation. The implemented small gateway counts request attempts; it is not a
dollar balance, subscription system, deployed backend or production credit store.
Timeouts are not automatically retried/refunded. Invite secrets stay separate from
projects and personal provider keys; Android stores them in a separate vault.

Custom website/domain is optional initially; an app-specific hosted privacy page
and operational public support contact are needed. A free support mailbox/alias
can keep a forwarding destination private. Encrypting an address with a key inside
the app cannot make that address private, and cannot conceal the public Play
contact. The detailed plan and current official sources are in
[the requested release guide](GOOGLE_PLAY_RELEASE.md).

## Android acceptance, then iPhone tester parity — 22 November

Owner decision: Google Play/Android stays the primary launch target. Most friends
use iPhones, so iPhone functional parity becomes the next platform milestone once
the Android workflow is accepted on the S21. This brings meaningful friend feedback
into the release plan before wider marketing; a native desktop app remains later.

One Flutter codebase remains the product. Share photo analysis, prompt generation,
design/refinement, local finishes, history and project schemas. Implement platform
file/save/share/key and permission bridges separately, then verify the same user
tasks on iPhone. Existing iOS scaffolding is not evidence of completed parity.
TestFlight provides the proposed friends' beta route; public Apple release can be
decided separately. iPhone findings improve Android/Chrome, but do not substitute
for Google's Android closed test. No account, paid membership, invitation, backend,
upload, signing change or new package was created by this planning update.

## Photo-first design and local finishes — 22 November

Wall tile follow-up: generic Wall/Tile controls already supported the operation
but obscured it. Compact room-aware shortcuts now apply wall, splashback or shower
tile choices to the selected layer, preserving its colour and selection. Kitchen
splashbacks start with subway/brick; bathroom walls use rectangular tiles, both
editable through the existing pattern chooser. Separate layers retain independent
floors and walls. Known room type wins; legacy room names supply a fallback.
Powder rooms/toilets do not suggest a shower. No recipe migration is needed.

Product direction: the initial photo analysis should do more of the design work,
so refinement improves an already coherent concept rather than filling gaps in
the original brief. Analysis now inventories visible surfaces, fittings, main/task
lighting, furniture, clutter and relationships across supplied views; uncertain
or hidden geometry stays uncertain. It asks for concrete coordinated replacements
within Full room / Partial / Precise scope, taking design initiative for a full
room even when comments are sparse. Protected features stay authoritative.

Workspace/setup now automatically reuse photo observations for New design only
when the working image and included context IDs match. They can survive changes
to style/palette/preferences without buying another analysis. The optional
AI-written prompt remains a separate reviewed, context-checked choice. Facts do
not silently follow a different generated viewpoint or enter precision polishing;
descriptions of old finishes must not undo an approved design.

The local editor now supports reusable wall/floor/splashback colour and tile
pattern layers: square, rectangular and brick, with grout, scale and angle.
These simple 2D patterns give inexpensive visual direction; they do not identify
room planes, measure products, simulate calibrated materials or solve perspective.
Tap selection is still a colour/edge heuristic; patterned floors may need outline
and erase. Saved recipes retain choices and masks through normal/protected copies.
Full PNG compositing preserves unselected source pixels and alpha.

Finish with AI saves the local composite, selects it as the working image and
prepares one precise polish of all selected paint/tile finishes together. It
does not contact a provider. Users can review/edit and separately confirm paid
generation. The prompt asks for boundary/material/perspective integration while
retaining the chosen room; without hard AI masks, unchanged surroundings remain
a requested behaviour, not a pixel guarantee. Real output quality needs a small,
deliberate model comparison; automated tests cannot establish design appeal.

Checklist follow-up, source `56814171d1`: the review dialog previously offered
only Close and Refine, making low-score continuation hard to discover. A checkbox
pinned above its actions now changes Refine brief into Proceed at any score.
Proceed enters the normal generation path and supplies a one-attempt review flag
so the same guidance is not duplicated in paid confirmation. It does not bypass
connection/required-input/paid-consent checks. Checkbox state is dialog-local and
resets on reopen; the separate 75%+ reminder preference is still written only after
confirmed send. No project, prompt, score weighting or published APK changes.

## Brief completeness guidance — 22 November

The requested percentage is implemented as Brief completeness, not an account
profile, physical scan percentage or quality forecast. A short checklist scores
supplied design direction locally. It counts photo presence, room type, goal/scope,
style, palette and the included layout rule. It does not assess photo content or
reward extra photos, provider setup, paid analysis or output count. Full-room
defaults allow an initial concept; adding a style/palette or goal adds direction.
Precision has a separate photo/instruction/retain-rest checklist, without irrelevant
whole-room requirements. Required-input protections still apply.

Source `65936b5efb` pins the percentage above Generate in all workspace tabs and
offers its detailed checklist on tap. Guidance is folded into the existing paid
send-confirmation, avoiding a second modal. Refine brief returns to inputs without
sending; a valid basic brief can proceed. After the user proceeds at >=75%, the
coverage reminder is remembered per room and mode on this device. It returns
below 75%, while paid consent remains and the checklist is always accessible.
Cancelling/refining does not acknowledge; storage failure leaves the reminder
eligible without discarding/duplicating a confirmed request. These preferences
are separate device metadata, not project mutations, recipe quality scores or
portable-file changes. Setup and Live also use the shared guidance/refine path.
Physical S21 acceptance awaits a requested package; no paid provider test or APK
was produced for this source batch.

## Lighting and regional language — 22 November

The reported result added under-basin/vanity light but retained the old main light.
The code's generic Update visible light fittings instruction left room for that
interpretation; the exact cause of the unseen request/result cannot be established.
Source `50196e8c85` now explicitly replaces visible unprotected main fittings in
selected lighting/full-room requests. Accent lights alone do not satisfy it.
Ceiling structure is distinct from its replaceable fitting; Keep/protection and
task-only qualifiers win. Analysis identifies main fittings/locations separately
from task/accent light and reports when the main fitting is outside the view.
This is stronger prompting, not an enforced image mask or a passed real-provider test.

The English UI mostly uses Australian terminology. Shared analysis/generation
guidance now relates benchtop/worktop/countertop, taps/faucets, rangehood/extractor
and fitting/fixture. Basin/washbasin/bathroom sink names the bowl; vanity is the
cabinet/counter unit, which may include it. These are not interchangeable edit
scopes. Photos and room context resolve meaning; no blind rewrite of user text.

Recommend Language & Region with AU/NZ, UK and US English first, a device
suggestion plus manual override, then reviewed non-English UI translations as a
separate stage. Neither selector nor full translation is implemented. The regional
style options (Japanese, Italian, etc.) are design influences, not interface languages.
Flutter supports device locale, supported locales and localized app resources;
changing AI wording alone does not translate custom UI strings. Primary reference:
[Flutter internationalization](https://docs.flutter.dev/ui/internationalization).
Keep historical prompts/settings intact and capture future wording choices in recipes.

Main navigation, 22 November: align the visible order with startup by listing
Projects first, Explore second and Library third. Settings is a separate cog-opened
page rather than another main destination, so Back returns to the current tab.
The prior Explore-first order and duplicate Settings destination are superseded
in source `75ffe41898`; no project-store or APK identity changes are involved.

## Workspace refinement from phone feedback — 22 November

The four tabs now have a clearer purpose: Room supplies source photos/analysis;
Style sets palette, influences and renovation extent; Refine holds the written
brief, output count and optional precise correction; Ideas reviews/selects saved
results. Generate is pinned across all tabs, so no final tab is compulsory.
Its controller calls the existing mounted session rather than creating parallel
request widgets. Paid confirmation, snapshot capture, save-before-send, per-result
saving, save retry and exit guards remain. Results open Ideas after the batch;
the Refine session retains stop-after-current and unsaved-result recovery.

Full room (all) is separate from precise correction and layout preservation. It
includes normal visible finishes/fittings updates without repeated ticking;
saved Keep/protected requirements override defaults. Included item selectors are
read-only until Partial is chosen; prior partial choices are retained. Partial
restricts the brief to selected/written changes and rejects an empty request before
generation. Layout stays fixed by default: a complete finish renovation is not
permission for structural work. Old records retain the prior broad-design default,
with no rewritten photos or erased settings; extent is saved in backup/recipes.

Palette tiles/swatches are smaller; the full chooser uses two columns. Style pages
contain at most ten choices, starting with curated common directions, not a claim
of measured market popularity. Selected styles remain summarized across pages;
Japanese/Italian/etc. remain available. AI observations and prepared prompt panels
start closed, preserving the separate saved Use AI prompt flag. Manual handoff is
an optional Refine disclosure; Autosave is in More tools and only pending/error
save feedback remains in the footer. Source `c2d523f4c0` passes **332 tests**;
published APK 1.0.16 is unchanged. Existing clips need a later control-location
refresh after layout acceptance. No paid app AI or real project changes.

## Requested private APK — 21 November, 1.0.16+17

The latest shared source `aba3ee136c` is now packaged with all completed room,
paint, Live-name and recorded-help improvements, retaining icon A, signing identity
and project stores. **327 tests pass**, analysis is clean, and the corrected Android
release build passes (20.4s). An unreleased emulator candidate exposed browser MP4
timestamp incompatibility; all seven clips now use developer-encoded standard H.264
baseline, zero-based constant-rate silent MP4s. FFmpeg is not shipped in the app.
The final APK verifies public-only asset hashes, signature, permissions, restricted
sharing and native ELF/ZIP 16KB alignment; 16KB runtime and S21 acceptance remain.
The final APK installs/launches on a read-only API 37/4KB emulator with existing
project metadata retained. Playback shows advancing frames, correct 27s duration,
pause, actual seek to 25s, fullscreen and written fallback. Chrome is rebuilt
(66.3s) at the same localhost:7357 address; actual desktop playback/seek also pass.
Older published APKs, real projects, photos, keys and the original brief are intact;
no paid AI call, store upload or production identity change. Launch gaps below
are unaffected: this requested package is for private acceptance, not public release.

## Owner privacy, payments, testers and Apple — 21 November follow-up

The owner prefers to finish the app before paying the Play registration fee.
Registration/payment and tester recruitment are deferred; no account/service was
created. Google-managed checkout is preferred, but the pricing model is not chosen.

Feedback proposal: send the in-app form to a small HTTPS receiving service; keep
the destination email and mail-service credentials in its private configuration.
This also supports AI-output reporting without leaving the app. Encrypting an email
and shipping its decryption key inside the package only obscures it; see
[Android's hardcoded-secret guidance](https://developer.android.com/privacy-and-security/risks/hardcoded-cryptographic-secrets).
Public-key encryption can separately protect report contents if desired, with the
private key kept off the app; it does not remove the need for delivery infrastructure.
Google Play still requires a public support email: use a dedicated mailbox/forwarding
alias rather than the owner's personal address. Configure replies through that
identity too. See [support contact requirements](https://support.google.com/googleplay/android-developer/answer/113477?hl=en).
No private email/key has been supplied or embedded, and delivery remains unconfigured.

For digital app purchases/upgrades, use Google Play's paid-download/Play Billing
path, rather than the Google Pay API for physical goods/services. Google processes
customer checkout, but a merchant payments profile and verified payout bank account
are still needed to receive revenue. An eligible separate payout account may keep
finances separate; users do not enter bank/card details into our app. Sources:
[Google Pay versus Play Billing](https://developers.google.com/pay/api/android/support/faq),
[payout bank requirements](https://support.google.com/googleplay/android-developer/answer/7161440?hl=en).
Selling in-app unlocks/subscriptions would require billing/entitlement work; a
store-managed paid download does not itself need an in-app purchase screen.

The 12-testers requirement is for a future new personal account's invited closed
test: recruits may be friends/family or volunteers found online, with Google accounts
and access to Android devices. They opt in via the Play test link and stay for the
required consecutive 14 days, actually exercise features and provide feedback.
It is not the first ten public installs or a star-rating campaign; feedback can be
private. See [testing rules](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

Apple code inspection confirms an iOS scaffold, purpose strings and compatible
camera/gallery/video plugins, but no completed iPhone release. Project file transfer,
creation save/share and native feedback adapters are Android-only; provider secrets
fall back to session memory on iOS. The iOS label and example bundle identity also
need release work. Keep the shared Flutter design/AI/local-data code and add native
adapters, iOS Keychain, Mac/Xcode and real-device checks. Official
[Flutter iOS release instructions](https://docs.flutter.dev/deployment/ios) require
macOS/Xcode; App Store distribution uses a separate Apple Developer membership,
currently [US$99 per year](https://developer.apple.com/help/account/membership/program-enrollment/).
No iOS parity, purchase integration or completed feedback service is claimed.

## Google Play launch requirements — checked 21 November 2026

This is a dated policy/product audit using Google's primary documentation. The
user confirms no Play Console account exists yet. The original prototype brief
is unchanged; public-launch work is the later objective. No Console action,
payment, provider call or publication was made during this review.

| Requirement | Current evidence and next action | Primary source |
| --- | --- | --- |
| Publisher account | US$25 one-time registration, identity/contact verification; personal owners also verify an Android device. Organisation setup generally needs a D-U-N-S number and matching business details. Choose the real publisher type and check public profile visibility. | [Registration](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en), [identity details](https://support.google.com/googleplay/android-developer/answer/13628312?hl=en) |
| New personal account testing | Accounts created after 13 November 2023 need at least 12 testers continuously opted in to a closed test for 14 days, then apply for production access and describe testing. Internal testing does not satisfy this closed-test gate. | [Testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en) |
| Upload/signing | Prepare a signed AAB and Play App Signing; APKs remain useful for direct tests. Current Gradle uses com.example.renovision_ai and the debug signing configuration. Establish the production ID/upload key and safe project transfer first. | [App Bundles](https://developer.android.com/guide/app-bundle), [signing](https://developer.android.com/studio/publish/app-signing) |
| Compatibility | Current SDK/last APK target Android 16/API 36, matching today's new-app baseline. APK 1.0.16 passes native ELF/ZIP 16KB alignment; final AAB alignment and 16KB runtime still need checks. Recheck Console at submission; dates change. | [Target API](https://developer.android.com/google/play/requirements/target-sdk), [16KB support](https://developer.android.com/guide/practices/page-sizes) |
| AI output reporting/safety | Add real offensive-output reporting without leaving the app and a process for receiving/reviewing it. General drafts/external email or browser handoff are not that implementation. Test provider refusals and protections. | [AI content policy](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en) |
| Privacy/Data safety | Public app-specific privacy webpage plus in-app access; document cloud photo/prompt processing, providers, keys, backups, reports, retention/deletion and SDK behaviour. Off-device provider traffic cannot be ignored just because the app owner has no server. Collection/sharing exceptions must be evaluated rather than guessed. | [User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en), [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) |
| Listing | App name up to 30 characters; short/full descriptions 80/4,000. Use approved A artwork as a 512px square PNG; create a 1024×500 feature graphic and 2–8 real phone screenshots. A longer YouTube preview is optional; phone help clips remain a separate user requirement. | [App setup](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en), [assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en), [icon](https://developer.android.com/distribute/google-play/resources/icon-design-specifications) |
| Declarations/reviewer access | Complete audience, content-rating, ads, privacy/Data safety and access declarations. Supply private instructions/access for all AI functions; do not expect Google to create/fund its own provider account or publish a review key in the app. | [Review preparation](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en), [review access](https://support.google.com/googleplay/android-developer/answer/15748846) |
| Money | Choose paid download versus free app with an in-app unlock before release. A free download cannot later become a paid download under that same app. Paid in-app digital features/credits need the applicable Play billing programme. Paid sales also require a payments profile; provider API bills remain separate. | [Pricing](https://support.google.com/googleplay/android-developer/answer/6334373?hl=en), [payments policy](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en), [merchant setup](https://support.google.com/googleplay/android-developer/answer/3092739?hl=en) |

Data-flow findings from actual source: direct AI sends selected, resized, metadata-
stripped PNG copies and the brief over HTTPS after confirmation; originals remain
in Hive. Live sends a captured reference, not continuous video. Android API keys
use Keystore encryption and their two preference files are excluded from OS backup.
Other app data is not explicitly excluded: Android may back it up under system
settings. Confirm/disclose the intended policy against
[Android Auto Backup](https://developer.android.com/identity/data/autobackup).
Recoverable room/design deletion retains bytes; permanent project/trash cleanup
is unfinished. Local-photo encryption is not implemented; export encryption is.
No RenoVision account, managed subscription service or analytics/billing SDK is
implemented. Do not claim that every photo stays on-device or that all stored
photos are encrypted. Review merged legacy READ_EXTERNAL_STORAGE and prefer
[system photo pickers](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en)
over unnecessary broad media permissions.

Product gaps can be scoped honestly: v1 can offer concepts, prompt-guided
corrections, local paint, comparison and manual project exports. Hard AI masks,
tracked moving-view AR, wallpaper, native Windows, sync and managed Pro are future
work. Current 64MiB raw-photo/100MiB portable-file limits and whole-image Hive
storage need realistic project measurements. Existing passing tests cannot prove
real device memory, provider quality, billing outcomes or store approval. Start
with an internal release candidate and use
[Play pre-launch reports](https://support.google.com/googleplay/android-developer/answer/9842757?hl=en)
alongside real S21/Android 16 testing. Record phone help against the settled UI.

## Desktop preview parity — 21 November

The desktop browser now serves all current shared Flutter features from source
`aba3ee136c` at the same localhost:7357 origin. Native Windows packaging remains
future work. A real desktop check found that Flutter's development server could
play the fragmented MP4 demonstrations but reported an incomplete duration and
could not seek near the end. The optional release launcher now compiles then
serves only build/web through a loopback static server with validated file paths,
correct MIME/HEAD/range responses and no-store caching. Flutter engine assets
are local. This changes serving, not browser project storage or source data.

All **327 tests pass**, analysis is clean and the release rebuild takes 51.2s.
Eight focused responsive cases pass. An isolated 1440px Chrome check confirms
the served source, Settings/help, duration/near-end seek, play/pause, full-screen
and written fallback. No paid AI, customer project/profile edit, new APK or native
Windows installer was involved. Restart through the existing preview launcher
with `-Release` and keep the same normal profile/origin for saved work.

## Help video direction for launch — 21 November clarification

The user wants in-app help to be short sections of the walkthrough eventually
used for launch: an actual task carried through to its result, with clear taps
and captions. Treat the current seven demo recordings as an initial implementation,
not finished launch footage. Once the interface is stable, capture real Android
transactions and native pickers using a dedicated sample project and genuine saved
outputs, without customer work or credentials in view.

Each help clip should answer one question, such as adding a photo, choosing a
palette, generating ideas, refining one, recolouring a selected wall, saving/opening
or using Live design. Roughly 20–45 seconds is a pacing target, not a hard limit.
Show the starting screen, taps and completed outcome; use readable captions and
optional narration. Label any shortened AI wait. Assemble the same footage into
a longer complete launch/onboarding walkthrough later. Final phone legibility,
matching release controls and updates after UI changes are acceptance criteria.
No store upload, paid generation or APK build is requested at this stage.

## Recorded help, room recovery and tap paint — 21 November source follow-up

Video-first help now has seven bundled recordings covering photo/design, capture,
Live, paint, library/recovery, Save/Open and models. They capture real production
Flutter widgets and disposable-store transactions with pointer highlights/captions.
They are not physical-camera footage or real-provider benchmarks: AI/camera/native
file selection are explicitly labelled simulations. Eight guides retain written
instructions. Playback is lazy, offline, muted, seekable and full-screen; it pauses
in the background. The official Flutter
[video_player package](https://pub.dev/packages/video_player) provides shared
web/Android playback; physical S21 decoder acceptance remains.

Rooms now have visible deletion with exact displayed-name confirmation. Records
are hidden from active lists/library and retained with photos/designs/approvals,
Undo and persistent Deleted rooms recovery. Project exports include deleted rooms.
No destructive migration/purge is performed. Project deletion is separate work.
Live type choices save immediately even with autosave off; legacy label/ID and
generic-name normalization gives Kitchen (Live), etc., without changing custom names.

Paint defaults to tap a connected colour/edge region, then choose a colour. A
dilated gradient barrier reduces leaks across frames/seams; similar adjacent
surfaces may still merge. Sensitivity and optional manual corrections remain.
Compact row-span masks (up to 1000px/eight layers) persist through drafts/history/
backups. Individual/all layer deletion works after reopening; clearing a saved
recipe can create an unpainted child. Local lossless output preserves pixels
outside the selection; source/parent images and approvals remain unchanged.

Changing the selected layer's colour replaces its RGB target and rerenders from
the same original base, without new selection or accumulated blending. Optional
Finish with AI saves this rough preview and prepares a precise correction with
the selected colours. Previous notes remain and stale AI-written briefs are disabled.
Generation needs separate confirmation; it creates a new version and may alter
other details because hard AI edit masks remain unfinished.

Feedback stays device-local until the owner provides a public support email or
HTTPS form. The UI explicitly says it has not been sent; no destination/receipt
is invented. No APK was requested for this batch; icon A and the 1.0.15 package
stay unchanged. Current source checks are recorded in Feature status.
Source `aba3ee136c` passes all **326 tests**, clean analysis, Chrome release
compilation (78.9s), Android Kotlin/plugin compilation (2m 52s), and seven local
video decode/seek/timing checks. Public demo assets total about 2.5MB.

## A confirmed for current branding — 21 November 2026

The user confirmed "yes a for now": RenoVision keeps the olive green background,
cream room outline and sparkle shown in candidate A. The deterministic exporter
now installs those assets, including Android adaptive/themed variants, web/PWA,
iOS/macOS and Windows icons. All 40 files match the reviewed candidate. The app
header/startup use the same vector painter. This is source/export verification,
not native iOS/macOS/Windows runtime acceptance.

The selection also accepts the earlier offer to apply the icon and make an
updated test APK, 1.0.15+16. **315 tests pass**, icon export passes, analysis is clean, and Chrome/Android release builds pass (138.1/155.1 seconds). The existing ID/signing/storage remain;
1.0.14 and earlier packages are unchanged. Header and compiled Android icon
checks distinguish this build from the previous preview-only artwork. Further
icon refinements can follow, but A is no longer awaiting approval for this build.

## Local paint and regional choices — 21 November 2026

The local-finishes proposal below is now partly implemented in requested test
APK 1.0.14+15. In the workspace, Paint walls opens a pinned-image editor with
area/colour steps: polygon, brush, eraser, Move/zoom, up to eight wall layers,
colour strip/custom hex, coverage, Undo/Redo and comparison to the actual starting
design. Selection is manual; windows, trim and furniture need explicit exclusions.
Luminance variation guides a colour approximation, not calibrated paint matching.
The preview uses up to a 1000-pixel long edge; sources above 24MP are rejected
without changing the original. Phone/browser latency still needs acceptance.

Drafts are bound to the working image; saved paint versions retain their underlying
source, editable layers and parent in history, without AI model/request provenance.
Saving adds a lossless full-frame PNG, without replacing the source or approving
the result. Reopening a paint version edits against its original base, avoiding
repeated colour blending. Saved-version layers can be restored explicitly with Undo.
Plain/protected backups and independent copies retain/remap these references.
Pixel tests check unchanged output outside the selection, eraser holes, alpha
and indexed PNGs. This guarantee belongs to local paint; AI precision is still
prompt/reference guidance. Wallpaper/perspective and automatic wall detection remain.

The style catalogue now has 23 choices. Regional influences groups existing
Scandinavian/Japandi/Mediterranean/French provincial with Japanese, Italian,
Moroccan and Indian. Select these with a base style and optional free text. Cues
respect selected palettes and protected geometry; they are not assumptions about
the user or a requirement to stereotype a whole region. Provider adherence still
needs real comparisons. Feedback draft tools are included, but delivery still
needs the owner's public support contact. **315 tests pass**, analysis is clean, and Chrome/Android release builds pass (111.2/234.8 seconds).

## Feedback entry points — 20 November 2026

The user wants online feature suggestions and issue reporting. The source now
adds Feedback to contextual Help and Feedback and ideas to Settings, with a shared
local draft, issue/feature categories, title/details, preview, optional build/
platform and copying. Draft failures retain text with visible retry feedback;
normal Back saves, and clearing requires confirmation. Drafts are not project data
or portable-export content. No photos, logs, project files/names or AI settings
are collected automatically. This needs no RenoVision login.

The email/HTTPS-form hooks are implemented, but delivery is not connected: the
owner has not yet supplied a support email or feedback URL. Both public build
definitions default empty. A private source repository is not a public feedback
destination. Email opens a composer for the user to send; a hosted form requires
copy/paste and explicit submission there. A handoff is not a receipt. No real
report was sent, and no service account/backend was created. Screenshot uploads,
public voting/roadmap, automated crash reports and ticket tracking remain later
options rather than hidden telemetry in the first version.

Originally verified with 305 tests, clean analyzer, release web compilation and
Android Kotlin compilation; now included in requested 1.0.14. See the Testing
guide for contact setup and real
Chrome/S21 receipt checks. This keeps initial feedback costs/support simple.

## Launch direction confirmed — 20 November 2026

Start with **Standard using the user's own AI API key**. The existing OpenAI and
Gemini connections support this without a RenoVision account or laptop relay.
An ordinary ChatGPT/Gemini subscription login is not a developer API credential;
the provider bills usage to the key owner separately. Grow Standard adoption
before investing in managed AI credits or other Pro services. No included AI
allowance, payment entitlement or pricing is implemented/promised by this decision.
Earlier credit-pack/price suggestions below are research hypotheses, not the
current launch plan. Local projects, image saving and sharing remain account-free.

Later, a subscription may include managed AI usage. Recommend a recoverable
RenoVision identity for cross-device entitlements, balances and account recovery;
that future service needs server-side payment/usage verification and spend limits.
Do not put a shared company provider key in the distributed app. This does not
require building accounts/billing now, or turning off the existing BYO-key path.

The user also wants an optional paid laptop/desktop companion later: capture,
analyse and explore on the phone, then refine on a larger screen. Chrome already
provides a desktop workspace, and one Flutter codebase can underpin a future
packaged Windows app. Portable project files carry rooms, original/generated
images, recipes and history between devices; API keys stay device-specific.
Windows packaging/install/export/key storage are not yet validated. Automatic
cross-device sync, accounts and a paid-download entitlement are separate future
work; exchanging a file is not live sync. No desktop installer is requested now.

### Affordable side-business experiment — 20 November

The user reports roughly one week and $30 spent developing the prototype and
wants an affordable app that can earn modest side income. Low development spend
supports trying a small launch; it does not establish ongoing maintenance,
support, distribution or AI costs. Keep the Standard BYO-key plan and test value
with real users before investing in hosted AI/enterprise services.

Suggested experiment, not selected or implemented pricing: free local viewing,
comparison/export and useful manual finish previews when those are built; test
an introductory **A$4.99 or A$9.99 one-off Standard phone-app unlock**, with the
user's AI provider charging separately. Compare with an annual licence only if
users demonstrate ongoing value. Keep existing project access/export available;
make included features, update terms and any later desktop charge explicit.
Do not promise lifetime AI or automatic access to future paid services.

At A$9.99, 100 purchases produce A$999 gross; 500 produce A$4,995 gross. These are
arithmetic examples, not demand forecasts, profit or take-home income. Allow for
store charges, taxes/refunds, support and maintenance. For Google Play, the
[current setup guide](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en)
lists US$25 once to register, and [service fees](https://support.google.com/googleplay/android-developer/answer/112622?hl=en)
depend on transaction, region and programme. Do not apply a blanket 15% assumption
to every Australian sale. No account registration, purchase or billing work is
authorised by this experiment alone.

Early validation: a small group completes a real room project, saves/reopens it
and exports a useful result without repeated help. Record willingness to pay,
BYO-key setup friction, provider spend and support time. Affordable local paint/
material tools could give no-key users a useful entry point; they are still on
the implementation backlog. Included-AI packs/subscriptions follow measured
cost and demand, with bounded usage. No final launch price is set.

## Verified outstanding-items and icon-refinement work — 20 November

Project Open/resume/conflicts, immutable version recipes with saved analysis and
reusable settings, plus startup loading/Retry now pass regression tests. All
296 tests pass, static analysis is clean and the final stamped web release build
passes (102.4 seconds). The renewed credits restored approval review; the
requested Android 1.0.13+14 update is built and verified from source `f69772aaa0`
(145.5 seconds). It includes Save image / Share creation alongside the recovery
and history changes; current icons and previous APKs remain unchanged.

Open preserves portable IDs and resumes matching unchanged content. Divergent
local/file content offers Keep local / Open file as copy instead of overwriting
either revision. Restore copy still remaps IDs, including historical analysis
references. New AI versions capture detached settings/analysis/model/quality and
expose Saved settings / Use these settings / Refine this design. Legacy versions
stay readable and show when structured settings were never recorded. Failed
imports and design writes clean up only new data; startup Retry does not clear
stores. Persistent Android file overwrites, analysis-fact caching, enforced masks
and measured large-library performance remain unfinished.

At that 20 November stage, A was shown but the user requested refinement and
design/colour alternatives. Assets/header were restored and candidates kept as
previews. This was superseded by the 21 November confirmation/application above.
A six-option
board is at `output/design-review/icon-refinements/renovision-icon-refinements.png`:
A olive/cream room, B lighter teal linework, C cream/olive framed room,
D navy/champagne geometric reveal, E terracotta/cream doorway and F graphite/sage
room planes. `tool/preview_brand_options.ps1` creates local SVG/raster previews;
no customer photo, model key or paid generation is involved. Name remains RenoVision.

## Settings, models and branding follow-up — 20 November 2026

The requested 1.0.13 update makes AI connection/models the first expandable card;
appearance now matches Home cover/Storage as a lower-priority collapsed card.
Delete is visible beside image tools for saved designs, with existing recovery
and baseline/original protection. Refine exposes New design / Precise correction.
Both support multiple outputs, but correction variations never inherit broad
renovation directions. Separate saved counts preserve old one-image correction
behaviour instead of silently multiplying requests.

The previous analysis-writing instruction proposed a conservative concept with
few comments; that contributed to cautious briefs. New design mode now calls for
a coordinated, visibly substantial redesign within allowed scope even with an
empty brief. Explicit narrow instructions/Keep features still take priority.
Models can still miss the request; no new real-room quality benchmark was run.

Official model guidance checked 20 November:

- [OpenAI image prompting](https://developers.openai.com/api/docs/guides/image-prompting)
  distinguishes 2.6 Sunburst for detailed/layout-sensitive editing from Flare for
  faster iteration. The new account-aware presets use Sunburst/medium for Room
  design, Flare/low for Quick ideas, and Sunburst/high for Final detail, falling
  back only within listed supported account models. These are starting choices,
  not a measured claim of the best result for Claylands. Saved choices stay saved.
- [Google image generation](https://aistudio.google.com/docs/image-generation)
  supports native generation/editing with Nano Banana models. Nano Banana 2.1 is
  the default Gemini editor; Nano Banana Pro is the complex-brief option. Gemini
  3.1 Flash-Lite Image is omitted because Google does not optimise it for the
  multi-reference/multi-turn editing this app needs. The adapter is implemented;
  a separate [Google API key](https://aistudio.google.com/docs/api-key) is required
  for actual testing. No key should be pasted into chat.
- [Claude vision](https://platform.claude.com/docs/en/build-with-claude/vision)
  supports image understanding, not image generation/editing. It could later write
  observations/briefs alongside an image renderer, with its own credentials.

Updated 25 November: the Gemini adapter now uses the documented
[generateContent image-edit format](https://aistudio.google.com/docs/image-generation?generate-content=true)
and [structured output](https://aistudio.google.com/docs/structured-output?generate-content=true),
with metadata-free photo copies and no automatic retry. It makes single-turn
requests without provider conversation IDs. Provider retention terms still apply.
Model-list checks send no photos and do not prove billable image access.
Nano Banana 2.1/2K is the starting preset; Quick ideas uses 1K, Final detail uses
available Pro/4K. These are documented capability-based starting choices, not a
comparative room-design benchmark. The owner now has a Google key; actual access,
quality and the previous generic model/option rejection need the next live test.
Settings → AI diagnostics retains safe local status/model/timing categories;
raw provider errors, keys, prompts and photos are excluded.

### Model-comparison shortlist

The user's goal is a small working choice of strong image editors to test before
launch, then rank from actual renovation results. Keep the four primary candidates:
Nano Banana 2.1 and Pro under Gemini; GPT Image 2.6 Sunburst and Flare under OpenAI.
Google's current guide recommends 2.1 over the previous Nano Banana 2 for new
projects; Lite is not optimised for this app's multi-reference/refinement workflow.
Do not inflate the shortlist with general chat models or claim a measured winner.
Earlier OpenAI 2.5 options remain for existing account/project compatibility.

Settings labels the recommendations as an unranked testing shortlist and links
directly to Compare AI models. The same guide is available through Help. It covers
fixed input photos/views/brief, one confirmed result per model, reselecting the
original between attempts, manual 1–5 ratings, actual time/cost and several rooms
and edit types. A selected generated image must not become the next model's test
input accidentally. No automatic paid benchmark, stored scorecard or leaderboard
is implemented; a tested ranking remains future work after real comparisons.

Code inspection found that normal New design attempts rotate creative direction
even for one output. A fixed-brief test switch now skips that planning appendix
and sends the prepared prompt exactly, for one output only. It is off by default,
resets off after restart, blocks multi-output attempts before sending and preserves
the room's ordinary saved output counts. Testers must still keep source photos,
supporting views and the prepared brief identical. Normal variety is unchanged.

### App name and icon options

RenoVision is the confirmed display name in source. The 20 November marked
image selected first-board **A** as the preferred name/icon direction:
olive-green tile, cream room-corner outline and reveal sparkle. This supersedes
the previous open choice. A was confirmed and installed on 21 November above. A preview
board made with built-in imagegen is retained at
`output/design-review/brand-options-2026-11-20.png`; its exact prompt is in the
adjacent `brand-options-2026-11-20-prompt.txt`. These are ignored local design
artifacts, with no customer photo/API key used. They are not installed assets.

The first-board options are retained below; A is now the confirmed current choice.

| Option | Working name | Mark |
| --- | --- | --- |
| A, preferred so far | RenoVision | Olive room corner with an ivory reveal glint |
| B | RoomShift | Two contrasting room planes suggesting before/after |
| C | RoomCanvas | Forest-green room frame with a warm terracotta plane |
| D | RenoVision | Bold RV monogram with a doorway detail |

These are creative options, not name-availability clearance. Android,
Flutter and browser display labels now use RenoVision in source; the package
identity and launcher assets remain unchanged.
After selection, create a dedicated clean adaptive icon and small-size previews;
do not crop a labelled comparison board into the shipping icon. Preserve the
application ID/signature and all stored projects regardless of display-name choice.

The new six-icon board is
`output/design-review/brand-icons-2026-11-20-v2.png`, with the exact built-in
imagegen prompt in the adjacent `brand-icons-2026-11-20-v2-prompt.txt`:
A Reveal lens, B Material layers, C Design sweep, D Open view, E Plan to space,
F Room scan. B emphasizes material/interior design; F emphasizes the camera.
The later board remains as design history. The latest marked preference returns
to A on the first board; this is a direction choice, not a finished launcher asset.

## Whole-project design audit — 19 November 2026

Reviewed the original product brief, substantive conversation requests, source
through `a948da0`, platform integration and existing test evidence. This section
is the current assessment. Later research entries are dated records; their old
implementation statements, provider catalogues and pricing are not current
verification. No competitor pricing or model recommendation was freshly researched
for this audit. Use [feature status](../FEATURE_STATUS.md) and
[next steps](../CODEX_NEXT_STEPS.md) for current implementation and priorities.

### Product position

Renovision has progressed beyond a static UI prototype: users can capture/import,
analyse, generate options directly on Android, select/refine, compare and resume
saved work. The user reports successful AI generation, project auto-reload and
useful camera overlays. Keep the existing work. The original differentiation is
still controlled changes to real rooms, and mask/compositor enforcement is the
largest missing part of that promise. Reliability comes before subscriptions or
claiming continuous AR.

At audit time source was ahead of APK 1.0.11. The subsequent requested **1.0.12+13**
package now includes the caption/room-entry/camera-handoff/layout/theme/backup
fixes, source stamp `3cb94c972c`. All 249 tests and static analysis passed again;
phone acceptance remains. The audit itself produced no APK or paid AI call.

### Rendered interface evidence

Eleven current-source views were rendered using fictional rooms and fake services,
not the user's live projects: 390×844 phone and 1440×900 desktop, real view metrics
and fonts. PNGs are retained locally in ignored `output/design-audit/`:
`projects-mobile`, `rooms-mobile`, `room-chooser-mobile`, `explore-mobile`,
`library-mobile`, `settings-mobile`, `workspace-room-mobile`,
`workspace-style-mobile`, `workspace-refine-mobile`, `workspace-ideas-mobile`
and `workspace-desktop`. This is layout evidence, not interactive Chrome/S21 testing.

The selected **Focus Canvas B** is cohesive. The large persistent image, warm
panels, consistent top tools and desktop split are worth keeping. The remaining
work is largely hierarchy and states, rather than another skin or full redesign.

| Screen | Assessment | Recommended improvement, not implemented in this audit |
| --- | --- | --- |
| Projects | Attractive cover and clear camera/photo entry; saved work remains relatively far down for a returning user | Move Continue/saved projects above discovery; shorten returning-user hero; keep most catalogue browsing in Explore |
| Rooms and spaces | Cleaner source now opens onto rooms/actions without the large Save panel | Keep this; fix singular/plural captions and verify save-failure feedback on phone |
| Room chooser | Compact photo tiles and readable labels; Camera/Photos/Live choices remain available | Add more representative photos over time; retain icon fallback and search rather than making every tile bigger |
| Workspace Room | Image context is clear but strip/dropdown/baseline chips and explanations repeat | One active-source/baseline header; put photos/analysis and their state above optional management controls |
| Workspace Style | First phone panel is largely the palette carousel; the chosen palette can initially be offscreen | Compact selected style + palette/swatches summary; bottom sheet or expandable picker for the full catalogue; scroll to the selected choice |
| Workspace Refine | Brief, output count and Generate fit well together | Distinguish Create concepts from Refine selected; show active source/edit mode without opening advanced controls |
| Workspace Ideas | Version captions are improved; copy/import comes before history | Put saved options/selection first and manual handoff in secondary tools |
| Explore | User-result review and inspiration share one destination, and empty-review text pushes samples down | Clarify its two purposes with a compact switch/sections; avoid making returning users pass an empty panel to browse samples |
| Library | Full-width image/caption/actions fix the narrow-column problem | Keep this layout; add search/filter/storage management only as library size justifies it |
| Settings | Theme choices, collapsed AI/privacy and cover controls are clearer | Keep global preferences here; use a selected-project file panel instead of an increasingly long list of project export panels |
| Desktop workspace | Large image plus separate controls is balanced and recognisably the same app | Keep adaptive split; preserve scroll position/focus and keyboard access rather than stretching a phone panel |

Do not reduce all type again to solve these priorities. Keep adequate touch targets,
system text scaling, accessible contrast and TalkBack semantics. Phone help must
open on tap/long-press, not depend on hover. Verify landscape, keyboard, long labels
and reduced-height screens on S21. A small amount of vertical scrolling remains
appropriate; horizontal tabs choose tasks, rather than hiding required fields in
unlabelled horizontal swipes or nested scrolling regions.

### Suggested final workflow

1. **Resume or start:** existing projects/Continue first; Camera, Photos and Live
   design remain equally available. Let users name/confirm the room type.
2. **Understand:** save original views, analyse with consent, show concise visible
   facts and unresolved questions. Cache facts for those images independently of
   style changes; don't invent a scan percentage or measured dimensions.
3. **Direct:** selected style/palette and a plain-language brief in a short summary.
   Whole-room defaults remain; advanced Keep/Replace controls are optional.
4. **Create:** confirm one/two/three clearly different directions and their actual
   model/quality/request count. Show stages and elapsed time, save each success.
5. **Choose:** history/options first, with full-screen zoom, compare, favourite,
   approval and recoverable delete. Preserve the exact recipe per result.
6. **Refine selected:** a dedicated correction input against that image and its
   recipe. Start narrow mode explicitly and create a child; never silently replace
   the approved baseline or reuse an unrelated image's settings.
7. **Resume later:** local autosave plus an understandable portable document.
   Open resumes the same document; Restore copy is a deliberate separate action.

These are refinements of the present architecture, not a proposed replacement app.
Camera-first users can stay in the viewer through steps 2–5, see the saved overlay,
then choose Continue to refine. New palette/style requests still take model time.

### What the supplied kitchen images show

The original photo and restrained redesigns preserve a U-shaped kitchen, sink
window, peninsula and tall appliance tower. The better charcoal/walnut examples
coordinate more surfaces and remove visual clutter. The user's preferred dining
presentation also has broader framing, pendants, stools/table, lighting and changed
glazing/scene treatment. It demonstrates the desired atmosphere and material
coordination; it does not establish that every architectural change matches the
real room. A conservative preserve-everything prompt can suppress those richer
choices, while a very open prompt can invent structure.

The product should distinguish **layout-preserving renovation**, **broader concept
exploration** and **local correction**, then carry explicit retained elements into
each. A material/design board should be typed as inspiration, not another camera
view used to infer geometry. No image analysis proves concealed structure,
buildability or plan dimensions. Explain visible observations and uncertainties
before turning them into design instructions.

### Architecture and release assessment

One Flutter app shares UI/domain logic across web/Android. Platform boundaries
already exist for files, camera, credentials and API transport. Modules cover
drafts/prompts, analysis, concepts, project files, backup crypto and image tools.
Keep those boundaries. Large UI/store files and eager image storage deserve
incremental extraction/profiling when their related features change; a generic
architecture rewrite would add risk without solving the known user problems.

The audit prioritised document identity/reopen and immutable per-version recipes;
the 20 November batch implements those, with same-destination persistence and
real-device acceptance still outstanding. Next: less redundant analysis, precise
edit enforcement and measured startup/image/export performance. Local encryption,
OS backup policy and recovery
need an explicit design preserving old data. Commercial backend/credits, production
signing/identity, privacy policy and store/iOS validation belong to a later release.
Historical competitor promises should not be used as validated capabilities or
as a basis for fixed pricing without current evidence and measured usage.

## Settings protection decisions — 19 November

App appearance is a device preference, separate from renovation palettes and
project-file revisions. Five coordinated light-page themes preserve the selected
compact layout. No appearance preference or API credential enters project exports.

Optional protected backups use the maintained
[cryptography AES-GCM implementation](https://pub.dev/documentation/cryptography/latest/cryptography/AesGcm-class.html)
and [PBKDF2 API](https://pub.dev/documentation/cryptography/latest/cryptography/Pbkdf2-class.html).
Version 1 envelope: ASCII `RVENC01\n`, big-endian uint32 JSON-header byte length,
header, ciphertext, 16-byte authentication tag. Header contains cipher/KDF names,
600,000 iterations, 16-byte random salt and 12-byte random nonce. The complete
prefix/header is authenticated associated data. Decoder validates file/header
limits and fixed supported parameters before derivation, then authenticates before
returning plaintext. Binary packaging avoids adding another base64 expansion to
the existing JSON/photo payload. File limit remains 100 MB. Filenames remain visible.

Protected files are opened as separate local projects without linking their file
handles to ordinary plaintext autosave. Normal JSON export remains a separate
explicit choice. Passwords are not saved, resettable or recoverable; a lost one
does not affect the existing local project. Native encryption runs in an isolate;
the browser uses the package's web crypto implementation. No cloud processing.

This does not add encryption to the existing Hive photo/metadata boxes. A future
local-store migration needs separate key management/recovery and interruption
testing, preserving current work. Android API-key protection already uses Keystore;
browser keys remain session-only. Public-release privacy/billing work remains.

## Camera-first design clarification — 19 November

User wants the reference acquisition, analysis, direction questions, generated
overlay and palette tuning in one viewer, then Continue to refine into normal
editing. This supersedes a capture-first navigation requirement, while retaining
the existing comparison mode. The new source implements that workflow with one
automatically captured reference and separately confirmed preview requests. The
user chose confirmation per request; bounded paid live sessions interest them as
a later option. Never imply a timer measures room coverage or silently send video.
Current image generation can take time; partial streaming is a possible next
latency improvement, not an implemented feature. Provider capabilities/limits:
[OpenAI image generation](https://developers.openai.com/api/docs/guides/image-generation).
Geometric room scanning, pose tracking and continuous video transformation are
separate research/engineering work. The source batch made no real AI calls or
APK; it is now packaged in the requested 1.0.11 test build.

Follow-up source after 1.0.11: Camera renovation's primary Design in live camera
action uses this viewer; the workspace editor is an explicit separate tool.
Saved results appear automatically over the camera (or wait for it to become
ready), with a toggle on the image. Keyboard visibility must not reset the
overlay. Continue to refine explicitly opens the selected result for precision
editing, preserving the whole-room brief. This correction is packaged in the
requested 1.0.12 APK; physical phone acceptance remains.

Consolidated 15 November 2026. Supporting notes, not another current task list.
Use the [project brief](../RENOVISION_PROJECT_BRIEF.md) for requirements,
[feature status](../FEATURE_STATUS.md) for actual implementation and
[next steps](../CODEX_NEXT_STEPS.md) for current priorities. Research entries are
dated individually; the 14 November prices were not rechecked during cleanup.
Proposals and the earlier roadmap are not completed features.

## Visual direction review — 18 November 2026

### Mobile controls and scroll review — 18 November 2026

User wants the required inputs for each task to fit one phone screen and asks
about vertical/horizontal navigation, competitor images and videos. Current
Focus Canvas workspace addresses section navigation; `reference_editor.dart`
still uses a vertical ListView with stacked tool, colour and width Wraps,
guidance and duplicate body Undo/Redo/Save controls. This is the next UI priority.

Primary references checked (public documentation, screenshots/alt descriptions,
demo text and tutorial transcript; no hands-on competitor-device claim):
- [Lightroom mobile workspace, including labelled editor screenshot](https://helpx.adobe.com/lightroom/mobile/get-started/workspace-overview.html): image-focused Detail view with grouped editing tools and separate options menu.
- [Adobe mobile masking video](https://www.adobe.com/learn/lightroom-cc/web/ai-assisted-masking-lightroom-mobile): around 01:08 the transcript describes managing masks and dragging the bottom tab to expand the panel. Relevant to panel design, not a claim Renovision already has AI masks.
- [Snapseed tool workflow](https://support.google.com/snapseed/answer/6155517?hl=en) and [selective gestures](https://support.google.com/snapseed/answer/6157827?hl=en): explicit tools, hold-to-compare, pinch/pan; selective adjustment uses vertical choice and horizontal value changes. Gestures supplement visible actions.
- [Homestyler photo/style workflow](https://www.homestyler.com/ai-room-design?lang=en_US): upload, illustrated style selection, room type where applicable, then generation.
- [Planner 5D room-design demo](https://planner5d.com/use/ai-room-design): multiple transformation choices and before/after comparison; useful as a visual interaction reference, not proof every private editor option fits one screen.

Recommended Renovision interaction: retain B's image-led workspace and compact
first-time room steps. For crop/markup, reserve the canvas and fixed Save/Cancel
actions; use a compact tool strip with contextual properties. Draw shows colour
and width pickers; Shapes shows its small shape chooser; Notes shows text actions;
Select exposes actions for the selected mark. Reuse the existing tools/history,
not a new unrelated editor. Put secondary guidance behind the existing info icon.
Keep Undo/Redo in the shared top toolbar instead of repeating body controls.

Horizontal browsing suits image versions, style cards and palettes. Short vertical
scrolling belongs inside the active control panel; expand/collapse it with both a
visible button and an optional handle. Do not assign whole-screen navigation
swipes over the image: they conflict with crop handles, drawing and panning.
Preserve readable controls, keyboard access and large text; do not guarantee zero
scrolling on every screen/device. Save/generation actions and errors must remain
reachable and visible. This review records a proposal; it does not implement a
new bottom sheet, editor layout or gesture scheme, and builds no APK.

### Selected references: HOMLY workflow + Forma styling

User selected **B / Focus Canvas**. It is now implemented in the shared Flutter
source: large persistent image and version thumbnails, compact retained control
sections, desktop split, dark warm canvas/olive actions and camera-first project
home. Existing room setup, photo selection, AI requests, approvals, save/restore,
deletion and key storage remain the underlying implementation. Generated artwork
was visual guidance; its illustrative account/share/duplicate controls were not
added as unsupported features. The layout is included in requested APK 1.0.9;
APK 1.0.8 retains the old layout.
Actual Flutter widget review captures (fictional photos, disposable in-memory
storage, local review font) are in `output/design-review/focus-native-*.png`.
The generated boards below remain the original choice references.

Image concepts requested on 18 November: three original raster UI boards generated
with the built-in image tool and visually reviewed: A Warm Studio, B Focus Canvas,
C Room Journal. Each shows room/camera entry and a design/refinement workspace.
Copies are in ignored `output/design-review/app-look-a-warm-studio.png`,
`app-look-b-focus-canvas.png` and `app-look-c-room-journal.png`; exact prompt set
is `output/design-review/app-screen-image-prompts.txt`. These are illustrative
concept images, not app screenshots or implemented screens. Illustrative account,
notification/share/duplicate icons do not add those features to the product scope.
Use existing supported tools when implementing the chosen direction. User choice
is pending; A's room entry with B's image-focused workspace is a possible blend.
No source UI change or APK build made in this image-concept batch.

Review examples prepared with the requested APK 1.0.8 batch:
`output/design-review/renovision-next-look.html` contains Warm Studio (split
image/control layout), Focus Canvas (larger image and compact refinement area),
and Room Journal (editorial project view with contextual controls). Room, Style,
Refine and Ideas tabs work locally; refinement text survives switches, sample
selection changes the preview and no AI requests or project writes occur.
Images are existing fictional examples, not versions of the user's real room.
Three layouts passed 19 browser checks at both 320px content width and desktop
width; Warm Studio desktop and narrow screenshots were visually inspected.
The actual app retains its current layout until the user chooses a direction.

Latest user selection refines the earlier Planner 5D preference:
[HOMLY — AI Interior Design App UI/UX & Motion Animation](https://dribbble.com/shots/27821170-HOMLY-AI-Interior-Design-App-UI-UX-Motion-Animation)
is the requested functional reference;
[Forma — Interior Design & Renovation Platform](https://dribbble.com/shots/27758267-Forma-Interior-Design-Renovation-Platform)
is the requested styling reference. Retain Planner 5D's room choices and compact
fine-tuning as supporting inspiration. These are preferences, not implemented UI.

Access limits: the two exact shot pages did not load reliably in the research
tool. HOMLY's animation/interactions have not been inspected. A related
[Forma shot from the same designer](https://dribbble.com/shots/27728147-Forma-Interior-Design-Renovation-Platform)
was accessible and describes a visual canvas with precise controls, materials,
style variations and version comparison in one workspace. Its published palette
includes cream, taupe, charcoal and brown. Do not attribute unverified interaction
details or a reusable Flutter template to either reference.

Renovision adaptation: warm cream/taupe surfaces, charcoal text, restrained earthy
accents, strong room photography and a clear type hierarchy. Keep Take photo and
Choose photos prominent, then room/style choices and one image-led workspace.
Desktop: image/comparison beside a compact control panel. Phone: image with
Room, Style, Refine and Versions sections, exposing only the active controls.
Keep the contextual toolbar, visible save/progress state, clean result thumbnails
and selected-design refinement. Preserve keyboard/large-text access even where
some scrolling is necessary. Use existing room records, images and version data;
make no storage migrations just for styling. Camera Renovation View remains the
priority new capability. Do not introduce estimated budgets, shopping catalogues
or contractor features solely because a reference depicts them. No APK requested.

User preference now selects the Planner 5D-inspired direction: image-led room
choices, fine-tuning beside the image, and minimal page scrolling. This supersedes
the earlier open choice between three visual directions. Use its public page as
inspiration, not proof of the exact layout in an authenticated editor or as a
template/source licence. Retain Renovision's own branding and shared Flutter code.

Proposed desktop workspace: image/comparison canvas and nearby versions, alongside
one compact active control panel (Room/photos, Style/colours, Refine or Versions).
On phones retain a useful image preview above a compact tabbed/expandable panel;
let content reflow for keyboard/large text rather than promising zero scrolling.
Preserve contextual toolbar ordering, drafts across tab switches, source/version
identity and paid-job state. Use the existing 42 room choices with suitable visual
category examples. A dedicated refinement panel and this responsive layout are
still proposed, not shipped. Camera Renovation View remains the main new feature;
this workspace design should accommodate it rather than replace that priority.

Private Android testing is already possible; public-launch readiness is a separate
milestone. Current priorities are a clearer image-led workspace, selected-design
refinement, real-device storage/lifecycle/network acceptance, interrupted-job
recovery and production distribution/signing decisions. No release date is set.

Reviewed public examples: [Homestyler photo/style workflow](https://www.homestyler.com/ai-room-design?lang=en_US),
[Planner 5D room-design presentation](https://planner5d.com/use/ai-room-design),
and [Dribbble interior-app concepts](https://dribbble.com/search/interior-design-mobile-app).
Public pages and concept portfolios are inspiration, not evidence of tested
in-app usability or reusable Flutter source. No template was purchased/imported.

Three isolated previews explore Warm Studio (recommended), Image Workspace and
Editorial Home. They use an existing fictional kitchen sample; concept thumbnails
reuse that image and are not newly generated designs. The previews do not save
projects or call AI. Source: ignored `output/design-review/renovision-directions.html`.

Recommended direction: warm neutral surfaces and restrained teal, large room-photo
project cards, a dominant design image, visual styles/palettes, compact refinement
controls and consistent contextual toolbar. Desktop should use the available width
for image and controls; Android should stack them with touch-friendly controls.
Preserve local storage, originals, version history and current AI integration.
Choose one coherent design system first; optional skins can follow. No broad app
layout changes were made in this research batch. Build an APK only when requested.

- [AI design workflow](#ai-design-workflow)
- [Competitor review](#competitor-review)
- [DecAI user-review lessons](#decai-user-review-lessons)
- [Pricing review](#pricing-review)
- [Camera workflow](#camera-workflow)
- [Earlier roadmap](#earlier-roadmap)
- [AI model choice](#ai-model-choice)

## AI model choice

Historical model research recorded 15 November 2026, retained below. Model IDs,
availability, documentation claims and subscription/credit offers were not
reverified in the 19 November audit; do not treat the table as a current buying
recommendation. The app filters its configured image-model catalogue against
account access, but that is not a capability/quality benchmark. Start testing
with the existing working OpenAI route; another provider, local GPU or 3D engine
is not required for the basic photo-analysis/design/refinement app.

| Job | First test candidate | Reason / limitation |
| --- | --- | --- |
| Photo observations and prompt drafting | [GPT-6 Luna](https://developers.openai.com/api/docs/models/gpt-6-luna) | Existing analysis integration; supports image input/structured output. Check observations rather than trusting invented measurements. |
| Detailed room edits | [GPT Image 2.6 Sunburst](https://developers.openai.com/api/docs/models/gpt-image-2.6-sunburst) | Documented for detailed visual work; a sensible first candidate for controlled renovation edits. Actual room preservation still needs testing. |
| Fast concept/refinement comparison | [GPT Image 2.6 Flare](https://developers.openai.com/api/docs/models/gpt-image-2.6-flare) | Documented for interactive iteration. Compare against Sunburst with the same source/prompt and record actual time, cost and adherence. |
| Existing baseline/fallback | GPT Image 2.5 Sunburst / Flare | Retain the working configuration and allow side-by-side tests; do not change old saved records or automatically retry with another model. |

The relay now exposes the configured default plus both 2.5 and 2.6 pairs.
These models and low/medium/high quality are listed by the
[image-edit API reference](https://developers.openai.com/api/reference/resources/images/methods/edit).
Configured options are not a verification of the user's account access. Default
remains 2.5 Sunburst at low quality, so adding newer options does not silently
change the first request. No live model benchmark has been performed.

The separate [Gemini Nano Banana 2.1](https://aistudio.google.com/docs/image-generation)
adapter is now integrated in source. It has independent credentials and mocked
request/error tests; real quality/value comparison remains pending. Another
provider is optional, not a prerequisite. No provider guarantees unaltered
architecture solely from a prompt.

### API access and subscription credits

A ChatGPT login cannot be pasted into the relay. However, eligible paid Pro and
Business subscriptions may claim API credits by linking an owned API organisation
using the same email, subject to the current conditions. Active credits can be
used without an API payment method. Check the official
[subscription API-credit guide](https://developers.openai.com/api/docs/guides/chatgpt-api-credits)
before adding paid credit; the user's plan/eligibility has not been checked.
A developer API key and model access are still required. A subscription is not
an automatic unlimited API allowance.

## AI design workflow



User requirement recorded 14 November 2026; implementation reconciled 19 November.
Photo analysis, editable AI prompt drafting and one/two/three concept requests
exist through direct OpenAI HTTPS or the optional relay. The user reports working
phone AI generation; systematic quality/diversity benchmarking is still pending.

1. Add photos of the same room; choose the primary view, colours and preferences.
2. Describe the desired changes in ordinary language and identify what must stay.
3. AI reviews the photos and preferences, then writes a specific renovation prompt.
4. Show the proposed prompt to the user for editing and approval. Surface unclear
   or contradictory instructions rather than silently inventing requirements.
5. Let the user choose how many design alternatives to request. Show the count,
   provider/model and quality before submission; actual billed-cost information
   is not yet implemented. Never generate paid alternatives automatically merely
   because a prompt was drafted.
6. Show the returned designs together with individual status/error information,
   useful titles, zoom/compare controls and keep/pass selection. Preserve successful
   results if another option fails; do not automatically retry billable requests.
7. Select one design as the approved baseline. Enter a further instruction or
   markup to improve that exact version. Save refinements as new child versions.

### Prompt-writing requirements

Presentation reference supplied by the user: a kitchen/dining design board with
two labelled alternatives, a wider room render, a floor-plan inset and material
swatches for cabinetry, benchtops and flooring. This is the quality/presentation
target. Keep the provided image unchanged. It is a style/presentation reference,
not permission to change another room's walls/glazing. Any plan measurements must
come from confirmed user measurements; do not treat generated inset labels as a
survey or invent verified dimensions. Later boards should make option selection
and refinement straightforward rather than flattening all alternatives into an
uneditable single image.

- Use the actual room photographs, selected palette, user changes and room memory.
- Separate layout-preserving renovation from a small-area precision correction.
  Replacing cabinets, flooring and appliances together is a renovation request,
  even when the walls and room footprint must remain unchanged.
- Explicit scope choices must carry through: selected flooring requires replacing
  the old floor pattern, and selected old telephone removal includes the handset,
  visible cord and repaired wall finish. Respect protected features and retain
  unrelated functional/safety equipment. Do not infer removals from style alone.
- Room-specific Keep / Replace preferences are authoritative input. For kitchen
  appliances, resolve individual overrides before writing the prompt, so one
  appliance never receives both Keep and Replace. New appliance models must be
  visibly new rather than merely recoloured. Filter inactive room-profile choices;
  do not treat name-based room type suggestions as photo observations.
- State the working viewpoint and supporting photo roles. Do not claim that
  multiple photos establish measurements or a verified 3D model.
- Explain which requested change affects which part of the room. Preserve the
  windows, openings, walls, viewpoint and approved choices unless explicitly changed.
- Treat a palette as guidance within allowed changes, not permission to repaint
  protected features. Handle "nothing to retain" without contradictory wording.
- Require the relevant image attachments. A copied text prompt alone has no photos.
- Retain the deterministic template as an offline/manual fallback, clearly labelled.

### Implementation sequence

1. Implemented: photo analysis/review, editable prompt, autosave and explicit use
   selection, direct internet API plus optional private relay.
2. Implemented: photo previews/consent, stale-input checks, storage-only retry,
   distinct bounded concept directions, sequential saves and partial-success
   handling. In-flight cancellation/recovery is not implemented; normal Back
   waits and a process kill can still lose a billed response.
3. Implemented 20 November: immutable per-version structured settings/analysis
   snapshots and history reuse/refinement. Next: separate photo-fact caching
   from changed design preferences.
4. Benchmark real-room preservation, diversity, refinement, time and usage on
   the same inputs before claiming one provider/model is better or cheaper.

### Current implementation

The offline fallback builds a labelled deterministic template. A connected vision
model can analyse photos and draft an editable prompt. Choosing it for generation
retains the authoritative current room requirements. The room stores its latest
analysis and current choices; each design stores the final prompt, source/parent/
supporting images, provider/model and request ID. New in-app generations also
freeze structured settings, historical analysis and model/quality in an immutable
recipe. Older/manual/editor versions may lack recipes; no missing history is
invented. These records survive project backups.
One/two/three concepts are separate sequential image requests from the same source,
with explicit varied directions. Manual edits, saved versions, favourites, approval
and branching already exist and should be reused rather than replaced.

## Competitor review

### Local finish editing review — 20 November 2026

User direction: use AI when it adds value; changing only wall paint or wallpaper
on an otherwise accepted photo/design should not require a new whole-room AI
render. This is an ideas/architecture review, not an implemented editor or a
paid competitor benchmark. Existing project data, source images and APK stay intact.

**Published patterns worth adopting:**

| Official evidence | Useful pattern for RenoVision |
| --- | --- |
| [Renovate AI paint guide](https://help.renovateai.app/en/article/painting-your-house-or-building-interior-walls-1dnnx96/) describes wall detection, palettes, mobile brush/Smart Fill, undo/reset, using earlier renovations and downloading | Edit the selected existing result, select walls, and keep colour choices beside the image. Reuse a corrected selection for further colour trials. The guide does not establish which steps run locally or incur AI usage. |
| [Renovate AI Color Finder](https://help.renovateai.app/en/article/how-to-use-the-color-tool-to-find-paint-colors-1woiafn/) documents extracting suggested room colours without changing the image | Add an eyedropper and saved swatches; later offer dominant-colour extraction. Sampled photo RGB is an appearance reference, not proof of an exact branded paint match. |
| [Benjamin Moore FAQ](https://www.benjaminmoore.com/en-us/faq), Website Questions 48, describes masking multiple surfaces on an uploaded photo and selecting colours; its Personal Color Viewer is not optimised for phones | Keep separate wall selections and colours, with deliberate phone-sized controls. Treat surface identity/selection as reusable editing data. This source does not disclose its internal algorithms. |
| [Roomvo paint feature sheet](https://hello.roomvo.com/hubfs/_Inbound%20Assets/Feature%20Sheets/inbound-feature-sheet-roomvo-paint-visualizer.pdf) describes different wall colours, retained surface texture, comparison, favourites, image download/share and product details | Make colour trials visual, comparable and easy to save; later attach selected material names/codes to a room board. Its realism/speed claims are marketing, not our measured acceptance standard. |

Renovate AI's [exterior paint page](https://renovateai.app/exterior-paint-visualizer)
also explicitly advertises AI-generated repaint renders. Similar-looking tools
can therefore use different pipelines; do not claim every competitor palette
change is a local operation. Its [homepage](https://renovateai.app/) lists paint,
wallpaper, flooring and cabinetry visualizers, but that alone does not establish
all features in every consumer plan or prove they work without AI.

**App position at the 20 November review (before 1.0.14):** `reference_editor.dart` / `reference_markup.dart` provide
crop and annotation geometry during editing, but save flattened reference images.
Their Select tool selects annotations, not room surfaces. `screens.dart` records
these as new image versions. `design_palettes.dart` supplies AI prompt directions;
it does not recolour pixels. There is no persisted surface mask, local paint/
wallpaper renderer or editable material-layer recipe yet. `RoomAnalysis` contains
text observations, not a usable wall segmentation map. Existing before/after,
version history, local storage and save/share controls are foundations to reuse.

**Recommended next functional batch: local wall paint.** Open an original or
accepted AI result, choose Finishes > Paint, select the wall once, and try colours
from a compact strip. Use a manual polygon/brush plus erase/edge correction first;
allow exclusions for windows, trim, furniture and fittings. A later optional
wall-detection assist could use an on-device model or a consented cloud call.
Once a suitable mask exists, palette changes can render on the device with no
generative request or API key. Never make a silent paid request when a swatch is
tapped. Show selection/preparation progress separately from ordinary colour updates.

The renderer should modify only the selected area and aim to retain its texture,
brightness variation and shadows. Flat colour fill alone gives an unrealistic
paint-over effect. Dark-to-light changes, reflections and missing texture limit
what simple compositing can reproduce; show a visual approximation, not an exact
paint/lighting simulation. Do not promise instant performance until measured on
Chrome and the S21.

Save named selections and editable layers against the source image ID, decoded
dimensions/orientation and source revision. Keep the base image untouched. New
AI renders, crops or different viewpoints need fresh or explicitly realigned
selections; they must not silently inherit an old mask. Store the selected colour,
blend parameters, mask and local-operation provenance in a compatible portable
recipe. Preserve the source generation's history separately; do not label a local
paint version as a new AI generation or assign it an invented model/request ID.
Autosave the working edit; Save version adds a child with a lossless full-frame
PNG and its editable settings. Approval remains explicit. Reuse existing sharing.

**Then wallpaper, followed by floor/cabinet finish trials.** Wallpaper needs an
image/swatch, repeat scale, offset/rotation and perspective controls; a flat
pattern over the entire photo is inadequate. Reuse the surface mask and excluded
foreground regions. Begin with owned sample patterns and user-imported swatches.
Preserve existing 3D shape; adding cabinets, changing layout, removing an object
or revealing hidden background remains a different AI/geometry task. Photo scale
is not a verified measurement. More complex reflections/occlusion need separate
quality work rather than a promise that every material swap is trivial.

**Phone workflow:** selected image stays visible; one Finishes action opens Paint
/ Wallpaper / later Floor / Cabinets. Pick a named surface, then use swatches in
a short bottom sheet, with Undo/Redo, compare to the starting design, Save version
and existing Save image / Share creation. Multiple paint choices can be compared
locally without spending a generation per colour. Keep the current AI New design
and Precise correction paths for edits that need synthesis. A no-key user can
still get useful manual finish previews, supporting the Standard launch plan.

Other worthwhile follow-ups: typed inspiration/material references, a simple room
material board, per-surface saved favourites and a base-style plus regional-
influence picker (e.g. Contemporary + Japanese/Italian). The then-current 19 styles include
Japandi/Mediterranean/French provincial/Scandinavian, but no dedicated Japanese or
Italian buttons. Local paint and regional choices were subsequently implemented
in 1.0.14 above; material boards/references remain proposed.

**Acceptance before shipping:** zero provider calls in manual/local mode, including
without a key/offline; correct mask mapping when zooming/rotating/resizing; saved
selections and layered recipes survive restart and plain/protected portable copies;
undo/cancel and failed saves preserve prior data; compare against the actual source
design; test occlusion/edges and dark/light paint; measure preview/export latency.
For a local full-frame PNG, assert decoded pixels outside the allowed mask/feather
band remain unchanged in the same oriented working frame. That guarantee belongs
to the tested compositor, not prompt wording or the current annotation tools.



Reviewed 14 November 2026 against RENOVISION_PROJECT_BRIEF.md and the current
Flutter implementation. Sources are official product/help pages. Features below
are advertised/documented capabilities, not independently tested performance or
guarantees. No competitor account, subscription or paid generation was used.

### What the competitors show

| Product / official source | Relevant capability or presentation | Renovision comparison and implication |
| --- | --- | --- |
| [DecAI](https://decai.ai/) | Dedicated interior/exterior, furniture, wall, floor and reference-style tasks, plus an AI design agent | The closest direct workflow benchmark identified by the user. Its published scope is broader than this prototype. Prioritise a coherent photo-to-edit-to-history experience and concrete surface controls. See the focused comparison below. |
| [Renovate AI Studio](https://studio.renovateai.app/home) | Separate tasks for flooring, paint, cabinets, object removal and selected-area editing; a guided design consultation | We have room-specific Keep/Replace controls and analysis/prompt drafting, but changes are still largely instructed in text. Add true selection/masking and concise task shortcuts. The published studio leads with the photo/upload action. |
| [Renovate AI editing help](https://help.renovateai.app/en/article/editing-images-overview-13vzd7k/) | Distinguishes typed edits, style exploration and a question-led consultation; accepts user component/material references | Keep Explore separate from Precision. Introduce explicit reference roles: material, inspiration and sketch, distinct from additional views of the same room. |
| [REimagineHome](https://www.reimaginehome.ai/) | Guided photo-to-refinement flow, inspiration/moodboard references and product/budget-oriented design | Our approved baseline and version history already support refinement. We lack clearly typed inspiration inputs, a material/specification board and a guided result-selection screen. Real-product availability and checkout are later-stage integrations. |
| [REimagineHome surface restyling](https://www.reimaginehome.ai/restyle-surfaces) | Dedicated wall/floor/cabinet material changes and subsequent refinement | Our palette is a direction, not a material sample. Add independent surface/material choices and reference swatches; verify actual output adherence. Do not equate a palette or checkbox with an enforced mask. |
| [Planner 5D room decorator](https://planner5d.com/use/ai-room-decorator) | A short photo/direction/generate/compare/refine journey, alongside its broader floor-planning ecosystem | We already support these ingredients but scatter them down a long workspace. Present clear stages, large images and accessible comparisons. A full measured 2D/3D planner is a separate scope from a renovation image concept. |
| [Planner 5D Android AI Designer](https://support.planner5d.com/en/articles/9310427-ai-designer-create-a-design-using-ai-android) | Separate furnishing, styling and arranging tasks; lets users explore another result before applying it | Provide bounded alternative generation and selection. Retain approval as an explicit action. These documented Android editor functions should not be assumed identical to the web photo workflow. |
| [Homestyler official AI update](https://www.homestyler.com/forum/view/2110216405773144066?lang=id_ID) | Partial renovation with furniture/material reference images; text guidance and moodboard generation | Explicit reference types and board export fit our kitchen use case. Model editing, CAD and its broader material-brush tools belong to a different 3D workflow; they do not establish that its photo edits preserve every pixel. |
| [RoomGPT](https://www.roomgpt.io/) | Simple one-photo entry point and prominent example imagery | Reduce setup friction and make returning to an existing room easy. Its public landing page alone does not establish detailed editing, storage or version-history capabilities, so those remain unknown in this review. |

Do not use competitors' advertised speed, popularity, exact colour matching or
structure-preservation claims as verified benchmarks. Plan/platform eligibility
can differ. See [Pricing review](PRODUCT_NOTES.md#pricing-review) for the separate dated
DecAI subscription/credit comparison and provisional Renovision pricing ideas.
Neither review recommends purchasing another service.

### DecAI: the closest direct benchmark

The user identified DecAI as similar to Renovision with a stronger experience.
That comparison fits its published product/workflow. This is an assessment of
documented capabilities and public screens, not a completed paid output-quality
benchmark or an inspection of its private implementation.

| DecAI experience | Renovision today | What to adopt |
| --- | --- | --- |
| [Its public workspace](https://decai.ai/app/home/) groups redesign, furniture changes, walls/floors and history into named tasks | One long workspace contains much of the functionality; provider setup/manual handoff can interrupt it | Give the user a room photo, a clear task and one next action. Keep advanced controls available in detail panels. |
| [Its gallery/edit update](https://decai.ai/blog/image-gallery-edit-and-more-features) describes a browsable gallery and editing a result directly without downloading/re-uploading | Versions and approved-baseline branching exist, but the gallery/return-to-room journey is basic | Show selected-result Edit / Compare / Approve actions together. Make original, current and approved images obvious. Add history filtering and thumbnails. |
| [Its style-transfer workflow](https://decai.ai/style-transfer) uses a room photo plus a distinct inspiration image | Supporting room angles exist; inspiration and material references have no dedicated roles | Store separate source roles and the intended influence. The user's kitchen board should guide style/materials without replacing the room geometry. |
| [Its room-design page](https://decai.ai/ai-room-design) documents dedicated finish choices and conversational iteration | Palette, Keep/Replace and AI-drafted prompts exist, with text-guided image requests; region enforcement is incomplete | Offer floor, walls, cabinets and appliances as visual tasks. Retain a concise room brief while applying follow-up edits to the selected baseline. |
| [Its FAQ](https://decai.ai/faqs) describes photo analysis and retained design history | Photo analysis is wired to the relay; live quality and the complete user flow still require verification | Make analysis produce visible observations and useful clarification, followed by an editable brief and a result saved to the same room. Verify this on the kitchen case. |

Do not assume that more styles, a polished gallery or claims about preserving
layout establish better image accuracy. Conversely, local originals and version
history are strengths to retain, not proven unique advantages over DecAI. Its
public materials do not establish every internal storage or locking behaviour.

### DecAI user-review lessons

Checked 15 November 2026 using the exact Android package supplied by the user,
[Google Play listing and visible reviews](https://play.google.com/store/apps/details?id=ai.interior.design.home.renovation.app),
and [US App Store reviews](https://apps.apple.com/us/app/ai-home-design-interior-decai/id6502747597?see-all=reviews)
for the same named product. Removing the referral/region query made the Play
listing accessible. This does not verify Android purchase prices. Both retrieved
store pages were US-facing; these are not Australian review statistics.

The visible selection is small, not a representative survey or a full review
export. Repeated App Store entries were treated as one review. Reviewers'
accounts are reported experiences, not independently reproduced defects or proof
of billing misconduct. No install, account, payment or photo upload was used.
Secondary review summaries were located but are not needed for the findings below.

**Direct Android examples:** Live Your Life (2 November 2026) objects to a
rating prompt before using the app. Mirko Hrovat (14 October 2026) reports that
the image placed twin beds differently from the written recommendation.
Vanessa B. (11 October 2026) reports added windows/changed ceiling height and
unclear subscription expectations. The listing displays 4.6 stars overall;
these selected complaints do not establish how frequently problems occur.
[Source](https://play.google.com/store/apps/details?id=ai.interior.design.home.renovation.app)

**Additional iOS examples:** MamaBoy+3 praises exploring alternatives.
wow werfcvhn (29 September 2025) reports invented space and difficulty with a
combined kitchen/living area. Ally Coyote (24 September 2025) reports ignored
colours and changed proportions. CD Bear (7 July 2025) describes misunderstood
weekly renewal. Augie247 reports interrupted refinement and having to repeat
the brief. These are separate iOS reports, not additional Android evidence.
[Source](https://apps.apple.com/us/app/ai-home-design-interior-decai/id6502747597?see-all=reviews)

The following are our product/engineering recommendations inferred from those
experiences, rather than assertions about DecAI's implementation:

| Priority | Renovision improvement | Existing work and acceptance check |
| --- | --- | --- |
| P0 | Keep the real room recognisable through changes and refinements | Layout/protection prompts exist; they are not enforced geometry locks. Check windows, doors, walls, viewpoint and usable circulation against the source; later add masks/compositing and outside-region warnings. Do not promise pixel-perfect retention from a checkbox. |
| P0 | Check the image against the approved brief | Scope, flooring/removal details, palettes and room-item choices exist. Show a concise requested-change checklist next to the result. Confirm tiles, phone removal, appliance updates and retained features visually; let the user flag a miss and refine the selected version. An AI check may assist, but is not a verified pass. |
| P0 | Resume without repeating the brief | Local drafts, versions and explicit approval exist. Finish normal-profile restart/restore tests and preserve preferences/source/parent across edits. Provider failure should retain the room context; local-save retry must not send another generation. Full conversation history and interrupted-request recovery remain incomplete. |
| P1 | Make exploration and selection straightforward | Add room cards/sample inspiration, then bounded alternatives with Compare / Choose / Refine. Current generation returns one image. A sample's composition must not replace the user's room geometry. |
| P1 | Support combined spaces explicitly | Current room profile is one selected type, including Living / dining; it cannot express independent kitchen/living zones. Later support named zones and retained features per zone. Multiple photos already exist, but do not establish a measured panorama or 3D model. Add an open-plan benchmark rather than assuming a wider photo solves it. |
| P1 | Make material choices concrete | Keep the existing palette and per-room controls, then add independent wall/floor/cabinet/benchtop selections and typed material references. Confirm the intended surface changes, instead of only checking whether palette text reached the prompt. |
| Later release | Make paid usage and interruptions understandable | Show exact output allowance, per-action usage, renewal total/period and cancellation route before purchase; avoid an early rating interruption. Billing and review prompts do not currently exist, so this is launch guidance. Do not promise every failed provider job is free; distinguish request failure, saved-result failure and poor adherence. |

Recommended sequence: save/restart correctness, visual room/sample entry,
clear result review and selected-version refinement, then bounded alternatives
and enforced region work. Evaluate genuine moving-camera AR separately. This
prioritises a trustworthy design journey while retaining the camera direction.

Extend the kitchen benchmark below with a narrow bedroom requiring two beds in
a specified arrangement and an open-plan kitchen/living scene. For each, compare
the brief, image and protected architecture; record retries and actual costs.

#### Practical benchmark using the kitchen

Use the same original kitchen photo and the same requested changes in both
systems. For the common-input test, use one primary photograph; test additional
room angles separately if both products support that role. Record the actual
settings, output count, quality, number of retries and any charges. No competitor
uploads or billable tests have been performed as part of this review.

Requested broad concept: keep the room walls, window, openings, camera viewpoint
and kitchen footprint. Use warm charcoal handleless push-open cabinetry and a
coordinated walnut colour/material direction. Replace the floor with large-format
warm greige tiles. Replace the visible oven, microwave, cooktop and extractor with
visibly new modern appliances in the existing positions. Remove the old wall
telephone and cord, and patch the wall. Do not add unseen appliances or openings.

Then choose a result and ask for one narrow correction, such as changing only
the benchtop finish while keeping the approved cabinetry, appliances, floor,
window and viewpoint. Compare the result to that approved source rather than
starting over from the original each time.

Score each check 0 = failed, 1 = partly met, 2 = met:

1. Room layout, window and viewpoint retained.
2. Old floor replaced, including visible edges.
3. Telephone and cord removed with a coherent repaired wall.
4. Requested appliances visibly replaced.
5. Cabinet fronts handleless and palette direction followed.
6. Unrelated/protected items retained.
7. Narrow follow-up edit preserves the approved result elsewhere.
8. User can resume the saved room and its versions after restarting.

Keep broad-concept and narrow-edit results separate. Also record usability,
time/retries and output cost independently; do not hide those in an image score.
Use the results to decide which gaps matter most. The next design batch remains
the photo-centred workspace, guided refinement and accessible saved alternatives;
reference roles and tested region edits follow as functional work.

### Current Renovision strengths

This is the dated competitor-review snapshot. The current inventory is in
FEATURE_STATUS.md; later source has added several items listed below as gaps.

- Original photographs are separate from generated/imported versions. Approved
  baseline, branches, favourites and before/after comparison already exist.
- Up to six same-room views, palettes, room types and individual Keep/Replace
  preferences are already implemented; new work should reuse them.
- Photo analysis and editable AI prompt drafting are wired to the relay, with
  consent, saved provenance and stale-input checks. They need live quality tests;
  they are not missing wholesale and are not an offline image model.
- Autosave, Save now, save-on-exit, named copies, PNG export and full project
  backups exist. Normal Chrome restart persistence and file-picker interaction
  remain required manual acceptance checks. Preserve the recovered kitchen files.

### Gaps and recommended order

| Priority | Gap / work | Completion evidence |
| --- | --- | --- |
| P0 | Finish the real saved-project restart and Save as checks | Restore the recovered kitchen once; close/reopen normal Chrome at the fixed address; verify photos, instructions, preferences, versions and a restored backup. |
| P1 | Responsive workspace centred on the photo | Large working image remains visible on desktop; grouped settings beside it. On phones, photo first, collapsible controls and a clear primary action. Keep controllers, IDs and save semantics intact. |
| P1 | Image-led project/library navigation | Room cover images, Resume room, meaningful status and version count; keyboard-accessible cards. Preserve text labels and empty/error states. |
| P1 | Clear result comparison and selection | Existing versions can be viewed A/B as well as against the original. Approve one baseline and refine that exact version without losing other ideas. |
| P2 | Multiple newly generated alternatives | An explicit result count and cost/usage confirmation; retain partial successes, no automatic billable retries, distinct IDs and parents. Currently generation returns one image. |
| P2 | Region-based edits, removal and protection | Brush/select a region, show its boundaries, send a compatible mask, composite where appropriate and test outside-region differences. Evaluate on the telephone/floor/appliance kitchen case. Do not claim precision guarantees until tested. |
| P2 | Reference materials and a design board | Distinguish a room angle from a material sample, inspiration image or sketch. Store the intended surface, finish, reference/source and notes. Export selected designs and swatches together. |
| P2 | Project organisation | Search/filter rooms and saved designs, useful version labels, reversible archive/trash/undo. Keep originals and restoration relationships safe. |
| Later | Measurement records, product links, budget and sharing | Use user-confirmed dimensions and source-linked specifications. User-entered budget is not a verified quotation; region/product availability needs validation. |
| Deferred | Full CAD/3D, live AR, retailer checkout, teams and billing | Treat as separate product stages, not prerequisites for reliable photo-based renovation. |

The first visual improvement should make the existing functionality easier to
use. More controls, styles or marketing badges alone will not solve unwanted
image changes or browser-session confusion.

### Current interface audit

Historical interface review before Focus Canvas. The current rendered assessment
is the whole-project audit at the beginning of this document.

Based on the actual Flutter widgets in lib/screens.dart and related controls:

- The working image follows the palette, saving panel, room analysis and photo
  controls. The room can be far below the initial viewport.
- Style, scope, appliance overrides, instructions and prompt details form a long
  vertical sequence. It is hard to change an option while seeing the room.
- Project/room lists and the favourites library rely mainly on small thumbnails
  and ListTiles, despite images being the core product.
- Explore, favourite, save-to-database, export and approve-baseline actions have
  different meanings. Make those labels consistent: Keep idea, Approve design,
  Save now and Export copy. Keep safety/status information close to its action.
- Advanced provider setup and full prompts compete with ordinary design work.
  Keep those available in collapsible detail panels; show connection/ready/error
  state without requiring the user to understand relay implementation details.

### Concrete proposed layout

Desktop: project/room breadcrumb, compact saving status and Save/Export actions;
a large working photo on the left; Style / Changes / Keep panels on the right;
room-view thumbnails and saved-option strip below the photo; one clear review
action. Compare and approve operate on the selected version.

Phone: same information and actions in a single column, with the room photo
first, comfortably sized controls, collapsible groups and a reachable review
action. Do not shrink desktop panels into unreadable columns.

Visual language: warm off-white background, restrained forest/teal accent,
charcoal text, consistent spacing and borders, larger photo areas and clear
selected/approved states. Retain sufficient contrast, text labels and keyboard
focus. Reuse Flutter's Material controls and current data/services.

### Retained review files

The earlier workspace prototype was superseded by the selected Focus Canvas
implementation; its disposable files were removed during cleanup on 19 November.
Current retained references:

- [Desktop widget capture](../output/design-review/focus-native-desktop.png)
- [Phone widget capture](../output/design-review/focus-native-phone.png)
- [Original selected B concept](../output/design-review/app-look-b-focus-canvas.png)

These captures use fictional sample photos and disposable in-memory storage.
They are not evidence of physical-device acceptance or paid AI quality. Original
kitchen photo/concept review copies are retained privately alongside them; the
actual project data, source photos and Chrome profile were not cleared.

The next implementation batch should cover the responsive workspace/navigation
and existing-version comparison first, followed by the multi-result/precision
work as separately tested feature batches. See CODEX_NEXT_STEPS.md.

## Pricing review

### Current refresh — 20 November 2026

This refresh takes precedence over the 14 November snapshot below. Public pages
and Australian App Store product lists were checked; no account, purchase,
checkout, image upload or paid generation was used. These are advertised consumer
prices, not competitors' underlying AI costs. Store catalogues may include old,
introductory or eligibility-specific products. They do not prove every offer is
available to a new customer, or establish Australian Android checkout prices.

**Public website offers.** Dollar currency was not explicitly identified in the
consumer pricing pages below; do not label these AUD or USD or convert them.

| Product / source | Recurring offer | Usage and other payment options |
| --- | --- | --- |
| [DecAI](https://decai.ai/pricing) | Plus $19.99/month, Pro $39.99/month; annual-view equivalents $4.99/$9.99 per month | Advertises 100/200 monthly generations. Non-expiring one-off packs: $29.99/100 or $69.99/300. Free: one web generation, watermarked. Annual equivalents are not monthly instalments; checkout totals/renewal terms were not confirmed. |
| [Renovate AI Studio](https://studio.renovateai.app/pricing), Trial and Error | Hobbyist $15/month, Pro $29/month, Max $99/month; current yearly promotion displays $5/$10/$33 per month, billed yearly | Usage described as more / 3× / 10× without absolute output counts. Pro adds estimation/staging/team tools; Max adds commercial/team/material features. Promotion duration, extra months, actual annual total and renewal price need checkout confirmation. |
| [Remodel AI](https://remodelai.app/faqs/), ReImage AI | Limited free renders followed by a paid subscription; FAQ directs customers to app stores | No numeric paid allowance or public web tariff established from this FAQ. Do not assume unlimited rendering. |

At full advertised usage, DecAI's monthly plans imply about $0.20 per included
generation; its packs imply about $0.30/$0.23. This is our arithmetic from its
published offers, not a model/provider cost estimate. Unused subscription allowance,
extra attempts, tools/quality and successful-result rate change practical value.

**Australian iOS benchmarks** (A$, separate from website offers and Android):

| Product / verified identity | Publicly listed purchase examples |
| --- | --- |
| [DecAI](https://apps.apple.com/au/app/decai-ai-home-design/id6502747597), COOL SUMMER LIMITED | Weekly A$9.99–14.99; annual A$49.99/59.99/99.99; annual sale products A$22.99/29.99; lifetime-labelled product A$79.99. The listing's description has different dollar examples, so use the regional product list as this benchmark, not as a verified checkout. Lifetime scope/AI allowance unconfirmed. |
| [Renovate AI](https://apps.apple.com/au/app/renovate-ai-house-design/id1661709494), Trial and Error, Inc | Explicit Weekly product A$14.99; Pro Yearly A$229.99; a product named PRO - 300 Credits A$14.99. Other PRO prices lack a period in their names. A credit is not established as one final design, and the 300-credit product's cadence/type is unconfirmed. |
| [Remodel AI](https://apps.apple.com/au/app/remodel-ai-home-design/id6446040791), REIMAGE AI INC. | Monthly variants A$9.99/12.99/14.99; yearly A$59.99/79.99/149.99; weekly A$7.99/9.99/14.99. Numeric paid render allowance not confirmed. |

**Name collision:** [remodelai.io pricing](https://www.remodelai.io/pricing) is a
different offer from ReImage's remodelai.app. Its App Store link identifies
app `6449718419`, while ReImage is `6446040791`. The .io page advertises annual
bills of $349/$599/$1,199, displayed as $29/$49/$99 monthly equivalents, with
1,000/5,000/25,000 monthly designs, model/quality tiers and three free designs.
Its header says unlimited but its cards give quotas; use the quotas pending
checkout confirmation. Currency is not explicit. Do not apply these allowances
to ReImage's app. Remodeled.ai and renovateai.io are further separate services.

Australian Google Play pricing was not verified: regional listing requests were
inaccessible, and the accessible .io-linked Android listing did not expose
subscription amounts. Mobile/web account portability, trial eligibility, renewal
price, refunds, credit expiry/rollover and render/credit conversion still require
the exact app's current paywall/terms. No iOS price is presented as an Android quote.

**Implications for RenoVision — recommendations, not implemented pricing:**

- Keep the confirmed Standard BYO-developer-key launch. Sell the project workflow,
  saved/refinable history, camera experience and control over provider/models.
  State before purchase that AI usage is billed separately by the user's provider.
  A lower app fee alone does not establish a lower total room-design cost.
- Test a modest one-off or annual Standard licence alongside monthly demand;
  homeowners may need the app for one project. No price has been selected, and
  earlier A$4.99/A$9.99 generation-pack ideas below are superseded launch hypotheses.
- Defer included-AI Pro until identical-room trials measure analysis, alternatives,
  refinements, failed billed attempts and support/payment overhead. Use bounded
  allowances with clear quality/count rules rather than promising unlimited AI.
- Compare cost per accepted room design, not credits or advertised images alone.
  Example test journey: one analysis, three concepts and two refinements, counting
  all billable attempts and recording which result the user accepts.
- Keep access/export of existing local projects independent of future AI balances.
  Treat the optional paid desktop companion and cross-device subscription rights
  as explicit later decisions, so phone customers understand any second charge.

Remaining pricing acceptance: inspect the three exact Android apps' AU paywalls
without purchasing; record offered period, annual upfront total, renewal price,
trial cutoff, included allowance, reset/expiry rules, top-ups and device coverage.
Then validate RenoVision's own costs/value with testers before setting prices.

### Historical snapshot — 14 November 2026


Checked 14 November 2026. Public information only; no account, checkout,
purchase, photo upload or billable generation was used. Prices and eligibility
can change. These are research findings and proposed experiments, not prices
implemented in Renovision.

### Published DecAI offers

[Web pricing](https://decai.ai/pricing), monthly view:

| Offer | Advertised price | Included generation allowance |
| --- | --- | --- |
| Free | $0 | 1 web generation; watermarked |
| Plus | $19.99/month (crossed-out $29.99) | 100/month |
| Pro | $39.99/month (crossed-out $59.99) | 200/month |
| One-off credits | $29.99 | 100 |
| One-off credits | $69.99 | 300 |

The page does not label the dollar currency; do not treat these as AUD.
Credit packs are advertised as non-expiring. Subscriptions renew automatically;
the FAQ says cancel at least 24 hours before renewal. Promotional renewal prices
and annual checkout totals were not verified.

[DecAI's own comparison article](https://decai.ai/blog/planner-5d-vs-decai)
advertises $4.99/month billed yearly, approximately $60/year, and a $199.99
lifetime option. This is a separate marketing source, not a verified annual
checkout or confirmation of the monthly plan's allowance on that offer. Do not
infer unlimited image generation from its promotional wording. Annual billing
requires the annual payment, rather than twelve optional $4.99 payments.

[Australian App Store listing](https://apps.apple.com/au/app/decai-ai-home-design/id6502747597):

| Listed purchase names | Australian prices |
| --- | --- |
| Weekly Premium variants | A$9.99 / A$12.99 / A$14.99 |
| Yearly Premium variants | A$49.99 / A$59.99 / A$99.99 |
| Yearly Sale variants | A$22.99 / A$29.99 |
| Lifetime | A$79.99 |

These are multiple listed products, not a guarantee every customer can choose
every offer. Eligibility, allowances and lifetime entitlements are unverified.
The Australian Google Play listing was inaccessible to this research tool;
Android prices remain unverified. Do not substitute iOS prices for Android.

### What this means for Renovision

DecAI's annual offers are already inexpensive. A lower upfront payment could
appeal to a homeowner renovating one room, but we cannot claim lower cost per
usable design until quality, included outputs and retry rates are measured.
DecAI already sells credit packs, so pay-as-you-go alone is not a unique feature.

Recommended initial commercial experiment after the prototype works reliably:

| Proposed offer | Test price | Scope to validate |
| --- | --- | --- |
| Local project workspace | Free | Original photos, preferences, saved versions and local backups; paid AI use separately capped |
| Starter pack | A$4.99 once | A small, explicitly bounded number of AI outputs; count set after cost testing |
| Larger room pack | A$9.99 once | More alternatives/refinements; show the exact remaining allowance before each generation |

These prices are hypotheses, consistent with the brief's approximate A$5
homeowner entry point. They do not establish profitability or a launch promise.
Keep subscriptions for demonstrated repeat demand. Avoid unlimited AI or a
lifetime payment that promises ongoing uncapped generation. Buying a design
pack should not determine whether someone can keep their existing local work.

For the user's desired workflow, three alternatives plus two refinements mean
five image outputs, plus photo analysis/prompt drafting. That is a useful test
bundle, not yet a promise that five outputs fit within the proposed starter
price. All follow-up attempts must be counted in the cost study.

### Cost validation before fixing the allowance

The current local relay defaults to `gpt-image-2.5-sunburst`, low quality, one
image per request, with `gpt-6-luna` for analysis. These are configuration values,
not evidence of model availability, current provider prices or actual costs.
No live cost benchmark or model-specific price was established in this review.

Measure the full photo-to-selected-result journey with the intended supported
provider/model before advertising output counts. Record analysis, each image
output, refinements, retries, input-image processing and high-resolution export.
Use current official provider billing, then allow for payment/store fees,
applicable taxes, hosting/storage, support and refunds. Keep currencies explicit.

For a conservative pack calculation:

    generation budget = net pack receipts - other variable costs - target contribution
    maximum outputs = floor(generation budget / conservative measured cost per output)

Include analysis and failed/repeated attempts in the measured workflow cost;
do not assume a failed provider request is free. Test a range of rooms and
multiple reference photos, rather than basing the allowance on the cheapest
single request. Show quality and output-count choices with their usage cost.
Protect the business with server-side allowances, usage records and spend caps;
never expose the provider key in the distributed Flutter app.

Before monetisation, finish reliable restart/resume testing, the visible
analysis-to-design flow, selection/refinement and output adherence. A cheaper
price will not compensate for lost projects or repeated unwanted changes.

## Camera workflow



Recorded 14 November 2026; reconciled 19 November. Embedded camera capture,
frozen comparison, manual same-view overlay and consented Live design are
implemented initially through 1.0.11. APK 1.0.12 also packages the main camera
handoff/automatic result overlay fixes and room-first Live entry. The user reports
useful earlier overlays; these later fixes still need phone acceptance.
Continuous, consistent whole-room AR is a separate milestone; composite exports
are not yet implemented.

### Updated first milestone and acceptance

Open a room's Camera Renovation View; show a responsive embedded camera feed.
Choose style/palette and explicitly capture the current view for generation.
Show genuine request progress while keeping the captured viewpoint available;
generation is asynchronous, not an instantaneous transformation of video frames.
When the result arrives, immediately enable a slider/opacity comparison against
that frozen source frame. Save the clean original, result and settings to the
existing room automatically, with the existing retry/error handling. Refinement
starts from the selected saved result. This frozen-frame milestone is distinct
from a later overlay on the running camera, which needs manual viewpoint alignment.

Accept on Android only after checking permission denial, portrait/landscape crop
and orientation alignment, app background/resume, failed/interrupted requests,
source/result persistence after restart and no extra requests when moving the
slider or phone. Manual camera overlays must be labelled approximate and should
be hidden or realigned by the user after viewpoint changes; automatic mismatch
detection must not be claimed before it is implemented and tested.

Technical references checked 18 November:
[OpenAI image generation](https://developers.openai.com/api/docs/guides/image-generation)
documents latency limitations (complex requests may take up to two minutes);
[ARCore session configuration](https://developers.google.com/ar/develop/java/session-config)
documents camera frames and device poses. Neither supplies instantaneous,
view-consistent whole-room renovation from one generated still image.

### Intended experience

Open a room, point the phone at it, choose the renovation direction, preview
alternatives, save the view that looks promising and refine it in the same app.
Keep the original capture, selected design and follow-up versions together so
the user can resume without repeating their setup.

### What other products document

| Official source | Documented experience | Distinction |
| --- | --- | --- |
| [DecAI FAQ](https://decai.ai/faqs) | Analyses an uploaded room photo and generates a design | A camera photo can supply the image, but the reviewed documentation does not establish continuous, tracked whole-room transformation. |
| [Dulux Visualizer](https://www.dulux.co.uk/en/expert-help/see-share-paint-introducing-updated-dulux-visualizer) | Previews wall colours in real time | A live surface-colour preview, rather than a complete renovation. This is a UK product source, not a verification of Australian availability. |
| [Roomle app listing](https://apps.apple.com/sg/app/roomle-ai-3d-room-planner/id732050356) | Advertises augmented reality and 3D live view alongside room planning | Camera/AR viewing already exists in this market. The listing does not establish generative renovation of every video frame. Device/region availability was not tested. |
| [IKEA Kreativ help](https://www.ikea.com/us/en/customer-service/knowledge/articles/e308d20e-895e-47ce-9aba-2f30c0d98a75.html) | Photo-based design, furniture placement and whole-room scanning on supported LiDAR devices | Room scanning and later design are distinct from an AI redesign that continuously follows a moving camera. |

These are documented/advertised capabilities, not independent device tests.
Avoid claiming camera input is unique or that competitors offer only uploads.

### What exists in this repository

`room_camera.dart` wraps the camera package for embedded preview/capture and
serialized lifecycle operations. `camera_room_view.dart` provides capture,
comparison and manually aligned flat overlays. `live_design_screen.dart` keeps
consented automatic still capture/analysis, options, confirmed image generation
and saved result overlay in the viewer, then explicitly continues to refinement.
Image picking/gallery import remains available. There is no continuous frame
analysis pipeline, pose/depth tracking, AR room model or moving-view renderer.

Original photos, supporting room views, preferences, AI analysis, generated
versions and approved-baseline refinement already provide much of the storage
and design workflow to reuse. Multi-option generation is now implemented as
two or three sequential saved image requests; it is not continuous video generation.

### Suggested stages

1. **Camera capture into the existing room workflow (implemented, acceptance ongoing).** Verify the current still
   camera path first. Design a guided capture/review screen, then show visible
   analysis and editable preferences. Generate explicitly bounded alternatives,
   choose one and refine from that selected design. Save each result immediately
   to its room; keep draft autosave behaviour and explicit save controls.
2. **Return-to-view comparison (implemented as a manual same-view overlay).** Display a saved design with adjustable opacity
   over the camera to help the user return to the original viewpoint. Start with
   a clearly labelled manual alignment aid. It is an approximate 2D comparison;
   moving to a different angle does not reveal a valid new design view. Pause or
   prompt to realign when the view no longer matches. Never describe this as a
   measured 3D model or reliable tracked AR.
3. **Tracked surface previews (future).** Investigate wall/floor selection, camera pose,
   surface mapping and material projection on supported Android hardware.
   Preserve openings and handle objects blocking surfaces. Validate tracking
   loss, occlusion, lighting and scale before claiming realistic live preview.
4. **Consistent whole-room AR (future).** A separate later investigation into room
   geometry, a persistent approved design and rendering from new viewpoints.
   Independent AI edits of successive frames can change the design between
   views. A successful image edit does not prove consistent moving-camera AR.

[ARCore anchors](https://developers.google.com/ar/develop/anchors) and
[depth/occlusion](https://developers.google.com/ar/develop/depth) document
components relevant to the later Android stages. They do not themselves turn a
generated flat image into a navigable renovation.

### What a snapshot must save

- The clean source camera frame as an immutable original, separately from any
  preview graphics; retain timestamp/orientation and source-room association.
- The actual rendered design/preview as a separate version, with the selected
  design ID, parent, prompt, palette and Keep/Replace preferences.
- Preview type and alignment/crop information where available. Label approximate
  camera composites so they are not mistaken for verified new-angle designs.
- Export/share a clean image without app buttons. For later AI refinement, use
  the clean capture or selected generated design as appropriate; keep overlays
  and annotations explicitly separate instead of baking the app UI into input.

Taking a snapshot should not silently trigger an AI request. Camera permission
does not imply permission to transmit a continuous video stream. Generate only
on an explicit action, show output count/usage and preserve partial successes.
Continuous cloud generation requires a separate cost/performance study.

### Testing and near-term priority

Continue Chrome on Windows for the project, saved captures, preferences,
generation/selection, refinement and restart tests. Use Android device tests for
real camera behaviour and any later tracking; desktop Chrome does not establish
phone AR performance. Retain gallery upload as an equivalent entry point for
existing photos and devices without the camera/AR capability.

Preserve reliable saving and the in-app photo-to-refinement journey. Validate
the latest same-view camera handoff/overlay on the phone before selecting an AR
dependency. Tracked rendering and clean composite export remain future work;
the existing manual overlay and five app themes are already implemented.

## Earlier roadmap

> Historical planning from 12 November 2026. Stage labels, setup tasks and initial acceptance checklists may be superseded by FEATURE_STATUS.md and CODEX_NEXT_STEPS.md. Optional private AI testing now exists; earlier no-AI planning is not the current implementation status.

**Working name; Android first; Flutter project; 12 November 2026.**

### Product vision
A privacy-conscious home renovation visualisation app: photograph a real room, explore ideas, save/reject alternatives, crop/zoom, mask a specific region, annotate with rough drawings or Paint sketches, refine an approved version without unexpectedly changing unrelated features, and maintain a local, portable project library.

One app; consumer, tradie and enterprise feature tiers later. iOS from shared Flutter source when ready. No public release during Stage 1.

### Non-negotiable design principles
- The original uploaded photo is **immutable**; keep an unmodified source copy and derivatives.
- A user-approved image is the **locked baseline** for each subsequent edit. Never silently switch to an earlier image or regenerate the whole room when an area is selected.
- Support **Explore** (creative full-room changes) separately from **Precision Edit** (selected-area-only corrections).
- Every edit tracks input image hash/id, prompt, mask/sketch, model/provider, result, approval/rejection, and parent version.
- Preserve project choices as structured **room memory**, including locks for windows, doors, architectural openings and floor edges.
- Prefer masked image editing and compositing when supported. Crop with adequate surrounding context, then blend result back into the unmodified image. Full-room generative regeneration is *not* reliable for exact changes.
- Compare output with baseline; highlight changes outside an editable area. This is a warning, not a structural guarantee.
- Keep projects and photo files on-device; add export/import and backups. No mandatory account for basic use.
- No API keys, photos, addresses, or payment credentials in source control. No AI processing during the UI-only prototype.

### Stage 0 — Developer setup
- Windows PC: VS Code already installed. Install Git, Flutter via the official VS Code extension, GitHub account/private repo, then Android Studio/SDK/AVD.
- Verify `git --version`, `flutter doctor`, `flutter devices`, `flutter run -d chrome`, `flutter test`.
- Avoid native Windows desktop build until needed (requires full Visual Studio desktop C++ tools, separate from VS Code).
- Optional IDE AI assistant: official OpenAI Codex or GitHub Copilot; use it for **coding**, not as the app's production AI service.

### Stage 1 — UI proof of concept (no AI/server/payments)
- Responsive app shell and navigation: Explore, Projects, Library, Settings.
- Project creation, room list, sample assets, local draft data model.
- Design preference browsing: skip/save; store saved idea and feedback.
- Later in Stage 1: import photo, rotate/zoom/crop, selected-area masks, simple sketch overlay; before/after compare; branch/restore versions; export/import project.
- Acceptance: works on Chrome and Android emulator; sample design interaction works; no cloud requests; no real photo leaves device.

### Stage 2 — Persistent local library and editing
- Durable project store (e.g. SQLite-based abstraction with platform implementation); photo files stored in app-private directories, with explicit project export/import.
- Separate original, approved baseline, current candidate and rejected branches.
- Edit records: project_id, room_id, source_id, parent_version_id, selection region/mask, prompt, locks, provider, timestamp, output id, approval state.
- Validate shutdown/restart, deletion, low storage, permission changes and failed imports.
- If browser prototype uses temporary storage, warn users; Android persistence is the source of truth until robust web persistence is implemented.

### Stage 3 — AI provider experiment
- Start with manual share-to-ChatGPT/Gemini/import workflow; inspect whether full photo + precise prompt is preserved through sharing.
- Optional developer-only controlled API experiment with ONE image-edit model: compare full-image edit vs crop + mask + compositing.
- Build a provider interface: `generateDesign`, `editSelectedArea`, `capabilities`, `usageEstimate`, `cancel`.
- Customer API key is NOT the same as their ChatGPT subscription. Do not embed reusable secrets in a distributed app. Confirm provider terms and a secure relay or delegated auth before enabling bring-your-own-key in public builds.
- Prepaid generation bundles and in-app billing deferred until outcomes and costs are measured.

### Stage 4 — Claylands benchmark and quality gates
- Test with original before photos (office/dining, kitchen, exterior), with user's permission and local-only test assets.
- Cases: remove fireplace; retain broad rear windows; only fix hallway passage/wall trim; change one cabinet; only fix skirting edge; preserve camera perspective; keep previously approved lighting/furniture; integrate sketch drawn in Paint.
- For every case: record expected edit region, non-edit lock mask, baseline output, result, provider, actual charge, user rating and corrections needed.
- QA metrics: outside-region pixel/perceptual change, room geometry consistency, prompt adherence, revision rework count, generation cost, crash rate.
- A pretty output that changes unrelated walls or windows **fails** precision mode.

### Stage 5 — Android distribution to private testers
- Chrome for rapid UI iteration; Android Studio emulator for Android behavior; USB or wireless connected physical Android phone for camera/pinch/gesture/permissions.
- Use `flutter run` for debug installs, then `flutter build apk` for private APK testing. No Google Play account required to run personal-device debug builds.
- Test APK signing, package identifiers, reproducible build, permissions, data export and safe failure when AI unavailable.
- Review side-loading warnings and only share private builds with trusted testers.

### Stage 6 — Public launch
- Before public launch: security/privacy review, provider data-processing review, AI content reporting/policy review, accessibility, crash reporting with privacy controls, terms and privacy policy.
- Google Play Console developer registration, listing, screenshots, release signing, developer verification and applicable closed-testing gate.
- Build Android App Bundle (`flutter build appbundle`), submit via Play Console. Prepare one app with feature tiers and Google Play Billing for digital content.
- Pricing to test: one-room free trial, optional paid local project/pro features, prepaid generations (capped), watermark only when our paid AI service provides an unlockable preview.
- Track net unit economics: gross revenue - store fees - AI inputs/outputs/retries - infrastructure - refunds/support.

### Stage 7 — Later expansion
- Level 2 camera-aligned comparison (not live generative AR), device capability detection and fallbacks.
- Tradie features: separate clients, branded exports, job folders, controlled sharing, team review.
- Enterprise: central accounts and storage, tenancy isolation, access roles, governance/compliance, billing and audit logs.
- iOS: reuse most Flutter/UI/business logic; Mac + Xcode for iOS builds, testing and release; platform-specific camera, storage and in-app purchases adaptation.

### Initial architecture sketch
```
Flutter UI
  -> Project controller / room design state
     -> Local project repository + photo storage
     -> Edit workflow (prompt builder, crop, mask, sketch, approval)
     -> AI Provider Adapter
        -> Manual handoff/import (Stage 1-3)
        -> Secure API service / approved delegated auth (future)
     -> Export/import service
```

### Privacy/security checklist
- Make original images immutable; encryption at rest where appropriate; avoid saving photo EXIF/geolocation.
- Default local-only storage. For cloud edits, obtain informed consent before transmission and identify the provider.
- Use private code repo, `.gitignore` for sensitive files, strong GitHub MFA; do not commit tokens, test photos or release signing keys.
- Platform backups may back up app data; review Android backup rules and communicate data handling truthfully.
- Public API service must authenticate/limit generation usage and prevent abuse; do not trust client counters.
- Export and delete functions, readable data-retention disclosure, provider retention review and breach response planning before launch.

### First demo acceptance checklist
- [ ] Flutter SDK installed and `flutter doctor` runs
- [ ] Private GitHub repo created
- [ ] `flutter run -d chrome` opens Renovision demo
- [ ] Explore > Save idea > Library shows saved concept
- [ ] Projects > Create project adds a project
- [ ] `flutter test` passes
- [ ] `flutter analyze` is clean
- [ ] Android emulator starts app
- [ ] First real photo import milestone planned (not part of starter)

### Official references
- Flutter install via VS Code: https://docs.flutter.dev/install/with-vs-code
- Flutter Android setup: https://docs.flutter.dev/platform-integration/android/setup
- Git for Windows: https://git-scm.com/install/win
- GitHub private repo setup: https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository
- Flutter Android deploy: https://docs.flutter.dev/deployment/android
