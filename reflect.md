
用戶功能
Super Admin	創建 Organization、管理多間學校
Admin (學校管理)	用戶管理、邀請老師/家長、出席統計
Teacher (老師)	考勤打卡、記錄狀態、相片分享、週計劃、Checklist、即時通訊
Parent (家長)	每日狀態查看、相片相簿、老師對話、文件簽署


技術化用戶功能描述
🔴 Super Admin
Tenant Provisioning: 創建 Organization/School documents，生成邀請 token
Custom Claims Management: 設置 Firebase Auth custom claims
Cross-tenant Access: 通過 isSuperAdmin claim 繞過 security rules
🟠 Admin (School)
User Provisioning: 調用 Cloud Function adminCreateUser/adminUpdateUser
Invitation System: 生成 secure token，通過 email 發送邀請連結
School Member CRUD: 管理 schools/{schoolId}/members subcollection
Attendance Analytics: Query aggregation + CSV export (csv package)
🟢 Teacher
Attendance Tracking: Update dailyStatus documents with real-time sync
Photo Upload Pipeline: Image picker → Compression (flutter_image_compress) → Firebase Storage → Firestore metadata
Real-time Messaging: Firestore snapshot listeners on chats collection
Weekly Plan CRUD: Manage weeklyPlans collection with date range filtering
Checklist Records: Template-based record creation + status tracking
🔵 Parent (Student)
Real-time Status Dashboard: Consume Firestore streams (todayDisplayStatus)
Photo Gallery: Grid view with lazy loading from Storage URLs
Bidirectional Chat: Real-time messaging with unread count badge
Document Workflow: PDF rendering (flutter_pdfview) + signature submission + FCM notification triggers


Progress of what I made:
At first, my direction is to create a common daycare app for teachers to record and communicate with parents. And the selling point is white-labeling, the center can have their own app with their own logo and name. After discuss with an enterpuner, I found out that I should focus on solving problem for them and being more useful rather than fancy.
So I changed the product to be more focus in operative level, administrative work, helping the center digitalize their records and process their daily/monthly work automatically. 
So my app has been through a single tenancy to multi-tenancy process. 

Why I start?
I have few friends working in early childhood education field, and I found out that they are using text message to communicate/reporting with parents. they don't have a system for operation and administrative work. The more I investigated, I found out that they need to submit studnt's attendance hours every month to the government, and some of them need to calculate manually on paper since the center didn't digitalize their records.  And most of the records need to store for years. 


Why my MVP not adopted?
I have interviewed a few operators and owner for my MVP. I found out that I overestimated the complexity of the administrative work. The government has been improving their system to make it easier for centers to submit their records, but they did not updated it on their website and guides. For the centers that did not go digital, most of them have a serious safety concern about privacy, they would rather develop their own system than using third party app.
So I stopped my MVP because there are already mature systems on the market and my selling point is not good enough to make them switch to my app. If I need to compete with them, I need to use more budget than I can afford and the revenue is not enough to cover the cost, so this investment is not worth it.


What I have learned?
I understand more about the market and how it works by the interviews. I have made too much assumptions when I was head down to my app.
Developing a product that is maintainable and scalable, following MVVM architecture, add unit testsAuthentication, Rules, Cloud Function, Multi-tenancy.

An engineering mindset: when I design a function, I always think about user -> action -> outcome.
Also, before I need to design a function, I should be more clear about the goal. There are always multiple ways to solve a problem. So Goal -> solution. (for example, if the goal is for teacher to remind the parent or telling what the student is doing in school, I can use post and notification function for status and chat function)

Prompt engineering skills: AI sometimes will find the easiest way to "solve" the bug you found, but it's only a workaround. I need to use fresh analysis, dig deepper to find the root cause etc. 
Also it's more useful to provide console/terminal output to fix the bug, than just describe the issue.



Biggest Bug
when I first set up the status function for teachers to record students' status, since every teachers need to get a real-time update, I have setup a stream for every student, so this is the classic N+1 problem. And I didn't found out until I did a code review and I use denormalization to solve it at the end. It was a good experience for creating a scalable and maintainable app in the future. 
Biggest Challenge
when I switch the app from single tenancy to multi-tenancy, it's a new way for how the data being processed and stored. I need to setup a new way to handle authentication to make sure the data is secure and user can't access other tenant's data. 


Future
After I have complete a whole lifecycle of this MVP, I gain a lot more confidence about creating a product that can be maintainable and scalable. I also have grown stonger willpower to overcome the challenges and make the product better. 