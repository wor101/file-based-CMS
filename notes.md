**Implement User Registration**
1. create registration page
2. Create YAML file to hold users pending approval
3. Create Admin only page to approve or refuse users
4. For approved users remove them from the pending file and add them to the users.yaml file


**Register Page**
1. Form to submit username
  - need to check for duplicates
2. Form to submit password
  - need to enter twice and confirm same
  - need to encrypt with BCrypt
  - 

**Admin Only Page**
1. Create new /users/pending.erb page that is only accessible by admin
2. Display list of pending users
3. add buttons to accept or reject
  - accept button should add to users.yaml & delete from pending_users.yaml
  - reject should delete from pending_users.yaml