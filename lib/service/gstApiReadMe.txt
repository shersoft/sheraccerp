/**Master GST*/
const GSTPortalLink="https://api.mastergst.com"

Authentication : Authentication API

#1. GET 
​/einvoice​/authenticate

Authentication Request

Parameters
Name	Value	Description	Parameter Type	Data Type
email *
email - User Email
User Email

(query)	
string
username *
username - User Name
User Name

(header)	
string
password *
password - Password
Password

(header)	
string
ip_address *
ip_address - IP Address
IP Address

(header)	
string
client_id *
client_id - Client ID
Client ID

(header)	
string
client_secret *
client_secret - Client Secret
Client Secret

(header)	
string
gstin *
gstin - GSTIN number
GSTIN number

(header)	
string
Responses
Code	Description	Links
404	
Not Found. If requested entity is not found or if requested API is not found.

No links
500	
Internal server error
**************************************************************************
#2.Get GSTN Details
Get GSTN Details for a given GST Number

GET
​/einvoice​/type​/GSTNDETAILS​/version​/V1_03
Get GSTN Details

Get GSTN Details for a given GST Number

Parameters
Name	Value	Description	Parameter Type	Data Type
param1 *
param1 - GSTN Number
GSTN Number

(query)	
string
email *
email - User Email
User Email

(query)	
ip_address *
ip_address - IP Address
IP Address

(header)	
client_id *
client_id - Client ID
Client ID

(header)	
client_secret *
client_secret - Client Secret
Client Secret

(header)	
username *
username - User name
User name

(header)	
auth-token *
auth-token - Token
Token

(header)	
gstin *
gstin - GSTIN number
GSTIN number

(header)	
Responses
Code	Description	Links
200	
Successful, Get GSTN Details.

No links
404	
Not Found. If requested entity is not found or if requested API is not found.

No links
500	
Internal server error
*********************************************************************
#3. Get Sync GSTIN From CP
Get Sync GSTIN details from Common Portal

Show/Hide|List Operations|Expand Operations
GET
​/einvoice​/type​/SYNC_GSTIN_FROMCP​/version​/V1_03
Get Sync GSTIN From CP

Get Sync GSTIN From CP Details for a given GST Number

Parameters
Name	Value	Description	Parameter Type	Data Type
param1 *
param1 - GSTN Number
GSTN Number

(query)	
string
email *
email - User Email
User Email

(query)	
ip_address *
ip_address - IP Address
IP Address

(header)	
client_id *
client_id - Client ID
Client ID

(header)	
client_secret *
client_secret - Client Secret
Client Secret

(header)	
username *
username - User name
User name

(header)	
auth-token *
auth-token - Token
Token

(header)	
gstin *
gstin - GSTIN number
GSTIN number

(header)	
Responses
Code	Description	Links
200	
Successful, Get Sync GSTIN From CP Details.

No links
404	
Not Found. If requested entity is not found or if requested API is not found.

No links
500	
Internal server error

***********************************************************************
#5. Generate IRN
: Generate Invoice Reference Number (IRN)

Show/Hide|List Operations|Expand Operations
POST
​/einvoice​/type​/GENERATE​/version​/V1_03
Generate IRN

Generate Invoice Reference Number

Parameters
Name	Value	Description	Parameter Type	Data Type
email *
email - User Email
User Email

(query)	
string
ip_address *
ip_address - IP Address
IP Address

(header)	
string
client_id *
client_id - Client ID
Client ID

(header)	
string
client_secret *
client_secret - Client Secret
Client Secret

(header)	
string
username *
username - User name
User name

(header)	
string
auth-token *
auth-token - Token
Token

(header)	
string
gstin *
gstin - GSTIN number
GSTIN number

(header)	
string
Request body

application/json
The user provided basic details will be used to create a random user

Example Value
Schema
{
  "Version": "1.1",
  "TranDtls": {
    "TaxSch": "GST",
    "SupTyp": "B2B",
    "RegRev": "N",
    "EcmGstin": null,
    "IgstOnIntra": "N"
  },
  "DocDtls": {
    "Typ": "INV",
    "No": "MAHI/10",
    "Dt": "08/08/2020"
  },
  "SellerDtls": {
    "Gstin": "29AABCT1332L000",
    "LglNm": "ABC company pvt ltd",
    "TrdNm": "NIC Industries",
    "Addr1": "5th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "GANDHINAGAR",
    "Pin": 560001,
    "Stcd": "29",
    "Ph": "9000000000",
    "Em": "abc@gmail.com"
  },
  "BuyerDtls": {
    "Gstin": "29AWGPV7107B1Z1",
    "LglNm": "XYZ company pvt ltd",
    "TrdNm": "XYZ Industries",
    "Pos": "37",
    "Addr1": "7th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "GANDHINAGAR",
    "Pin": 560004,
    "Stcd": "29",
    "Ph": "9000000000",
    "Em": "abc@gmail.com"
  },
  "DispDtls": {
    "Nm": "ABC company pvt ltd",
    "Addr1": "7th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "Banagalore",
    "Pin": 518360,
    "Stcd": "37"
  },
  "ShipDtls": {
    "Gstin": "29AWGPV7107B1Z1",
    "LglNm": "CBE company pvt ltd",
    "TrdNm": "kuvempu layout",
    "Addr1": "7th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "Banagalore",
    "Pin": 518360,
    "Stcd": "37"
  },
  "ItemList": [
    {
      "SlNo": "1",
      "IsServc": "N",
      "PrdDesc": "Rice",
      "HsnCd": "1001",
      "Barcde": "123456",
      "BchDtls": {
        "Nm": "123456",
        "Expdt": "01/08/2020",
        "wrDt": "01/09/2020"
      },
      "Qty": 100.345,
      "FreeQty": 10,
      "Unit": "NOS",
      "UnitPrice": 99.545,
      "TotAmt": 9988.84,
      "Discount": 10,
      "PreTaxVal": 1,
      "AssAmt": 9978.84,
      "GstRt": 12,
      "SgstAmt": 0,
      "IgstAmt": 1197.46,
      "CgstAmt": 0,
      "CesRt": 5,
      "CesAmt": 498.94,
      "CesNonAdvlAmt": 10,
      "StateCesRt": 12,
      "StateCesAmt": 1197.46,
      "StateCesNonAdvlAmt": 5,
      "OthChrg": 10,
      "TotItemVal": 12897.7,
      "OrdLineRef": "3256",
      "OrgCntry": "AG",
      "PrdSlNo": "12345",
      "AttribDtls": [
        {
          "Nm": "Rice",
          "Val": "10000"
        }
      ]
    }
  ],
  "ValDtls": {
    "AssVal": 9978.84,
    "CgstVal": 0,
    "SgstVal": 0,
    "IgstVal": 1197.46,
    "CesVal": 508.94,
    "StCesVal": 1202.46,
    "Discount": 10,
    "OthChrg": 20,
    "RndOffAmt": 0.3,
    "TotInvVal": 12908,
    "TotInvValFc": 12897.7
  },
  "PayDtls": {
    "Nm": "ABCDE",
    "Accdet": "5697389713210",
    "Mode": "Cash",
    "Fininsbr": "SBIN11000",
    "Payterm": "100",
    "Payinstr": "Gift",
    "Crtrn": "test",
    "Dirdr": "test",
    "Crday": 100,
    "Paidamt": 10000,
    "Paymtdue": 5000
  },
  "RefDtls": {
    "InvRm": "TEST",
    "DocPerdDtls": {
      "InvStDt": "01/08/2020",
      "InvEndDt": "01/09/2020"
    },
    "PrecDocDtls": [
      {
        "InvNo": "DOC/002",
        "InvDt": "01/08/2020",
        "OthRefNo": "123456"
      }
    ],
    "ContrDtls": [
      {
        "RecAdvRefr": "DOC/002",
        "RecAdvDt": "01/08/2020",
        "Tendrefr": "Abc001",
        "Contrrefr": "Co123",
        "Extrefr": "Yo456",
        "Projrefr": "Doc-456",
        "Porefr": "Doc-789",
        "PoRefDt": "01/08/2020"
      }
    ]
  },
  "AddlDocDtls": [
    {
      "Url": "https://einv-apisandbox.nic.in",
      "Docs": "Test Doc",
      "Info": "Document Test"
    }
  ],
  "ExpDtls": {
    "ShipBNo": "A-248",
    "ShipBDt": "01/08/2020",
    "Port": "INABG1",
    "RefClm": "N",
    "ForCur": "AED",
    "CntCode": "AE"
  },
  "EwbDtls": {
    "Transid": "12AWGPV7107B1Z1",
    "Transname": "XYZ EXPORTS",
    "Distance": 100,
    "Transdocno": "DOC01",
    "TransdocDt": "01/08/2020",
    "Vehno": "ka123456",
    "Vehtype": "R",
    "TransMode": "1"
  }
}
Responses
Code	Description	Links
404	
Not Found. If requested entity is not found or if requested API is not found.

No links
500	
Internal server error

*********************************************************************************************
Get EInvoice Details
: Get e-Invoice details for a given IRN

Show/Hide|List Operations|Expand Operations
GET
​/einvoice​/type​/GETIRN​/version​/V1_03
Get EInvoice Details

Get e-Invoice details for a given IRN. You can fetch only past 48 hours of invoices from the time of IRN generation

Parameters
Name	Value	Description	Parameter Type	Data Type
param1 *
param1 - IRN
IRN

(query)	
string
email *
email - User Email
User Email

(query)	
string
supplier_gstn
supplier_gstn - Supplier GSTIN, only in case E Comm. operator is getting IRN details
Supplier GSTIN, only in case E Comm. operator is getting IRN details

(query)	
string
ip_address *
ip_address - IP Address
IP Address

(header)	
string
client_id *
client_id - Client ID
Client ID

(header)	
string
client_secret *
client_secret - Client Secret
Client Secret

(header)	
string
username *
username - User name
User name

(header)	
string
auth-token *
auth-token - Token
Token

(header)	
string
gstin *
gstin - GSTIN number
GSTIN number

(header)	
string
Responses
Code	Description	Links
404	
Not Found. If requested entity is not found or if requested API is not found.

No links
500	
Internal server error

******************************************************************************
Get IRN details by Doc Details
Get IRN details by Doc Details

Show/Hide|List Operations|Expand Operations
GET
​/einvoice​/type​/GETIRNBYDOCDETAILS​/version​/V1_03
Get IRN details by Doc Details

Get IRN details by Doc Details .you can fetch only past 48 hours of invoices from the time of IRN generation

Parameters
Name	Value	Description	Parameter Type	Data Type
param1 *
param1 - Document type
Document type

(query)	
string
supplier_gstn
supplier_gstn - Supplier GSTIN, only in case E Comm. operator is getting IRN details
Supplier GSTIN, only in case E Comm. operator is getting IRN details

(query)	
string
docnum *
docnum - Document number
Document number

(header)	
string
docdate *
docdate - Document date (dd/MM/YYYY)
Document date (dd/MM/YYYY)

(header)	
string
email *
email - User Email
User Email

(query)	
string
ip_address *
ip_address - IP Address
IP Address

(header)	
string
client_id *
client_id - Client ID
Client ID

(header)	
string
client_secret *
client_secret - Client Secret
Client Secret

(header)	
string
username *
username - User name
User name

(header)	
string
auth-token *
auth-token - Token
Token

(header)	
string
gstin *
gstin - GSTIN number
GSTIN number

(header)	
string
Responses
Code	Description	Links
404	
Not Found. If requested entity is not found or if requested API is not found.

No links
500	
Internal server error

*****************************************************************************
Cancel IRN
: Cancel Invoice Reference Number (IRN)

Show/Hide|List Operations|Expand Operations
POST
​/einvoice​/type​/CANCEL​/version​/V1_03
Cancel IRN

Cancel Invoice Reference Number. You can cancel only past 24 hours of invoices from the time of IRN generation

Parameters
Name	Value	Description	Parameter Type	Data Type
email *
email - User Email
User Email

(query)	
string
ip_address *
ip_address - IP Address
IP Address

(header)	
string
client_id *
client_id - Client ID
Client ID

(header)	
string
client_secret *
client_secret - Client Secret
Client Secret

(header)	
string
username *
username - User name
User name

(header)	
string
auth-token *
auth-token - Token
Token

(header)	
string
gstin *
gstin - GSTIN number
GSTIN number

(header)	
string
Request body

application/json
The user provided basic details will be used to create a random user

Example Value
Schema
{
  "Irn": "a5c12dca80e743321740b001fd70953e8738d109865d28ba4013750f2046f229",
  "CnlRsn": "1",
  "CnlRem": "Wrong entry"
}
Responses
Code	Description	Links
404	
Not Found. If requested entity is not found or if requested API is not found.

No links
500	
Internal server error

***********************************************************************************************
Generate Ewaybill
Generate the e-waybill using Invoice Reference Number (IRN)

Show/Hide|List Operations|Expand Operations
POST
​/einvoice​/type​/GENERATE_EWAYBILL​/version​/V1_03
Generate Ewaybill

Generate the e-waybill using Invoice Reference Number (IRN).

Parameters
Name	Value	Description	Parameter Type	Data Type
email *
email - User Email
User Email

(query)	
string
ip_address *
ip_address - IP Address
IP Address

(header)	
string
client_id *
client_id - Client ID
Client ID

(header)	
string
client_secret *
client_secret - Client Secret
Client Secret

(header)	
string
username *
username - User name
User name

(header)	
string
auth-token *
auth-token - Token
Token

(header)	
string
gstin *
gstin - GSTIN number
GSTIN number

(header)	
string
Request body

application/json
The user provided basic details will be used to create a random user

Example Value
Schema
{
  "Irn": "47d7ba1814b6ca6123c780ad289b0a24e30c1baed59a7417d29a54e7b00a6bdf",
  "Distance": 100,
  "TransMode": "1",
  "TransId": "12AWGPV7107B1Z1",
  "TransName": "trans name",
  "TransDocDt": "01/08/2020",
  "TransDocNo": "TRAN/DOC/11",
  "VehNo": "KA12ER1234",
  "VehType": "R",
  "ExpShipDtls": {
    "Addr1": "7th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "Banagalore",
    "Pin": 562160,
    "Stcd": "29"
  },
  "DispDtls": {
    "Nm": "ABC company pvt ltd",
    "Addr1": "7th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "Banagalore",
    "Pin": 562160,
    "Stcd": "29"
  }
}
Responses
Code	Description	Links
404	
Not Found. If requested entity is not found or if requested API is not found.

No links
500	
Internal server error

*****************************************************************************************
Get Ewaybill Details by IRN
Get Ewaybill Details by IRN

Show/Hide|List Operations|Expand Operations
GET
​/einvoice​/type​/GETEWAYBILLIRN​/version​/V1_03
Get Ewaybill Details by IRN

Get Ewaybill Details by IRN

Parameters
Name	Value	Description	Parameter Type	Data Type
param1 *
param1 - IRN
IRN

(query)	
string
supplier_gstn
supplier_gstn - Supplier GSTN
Supplier GSTN

(query)	
string
email *
email - User Email
User Email

(query)	
ip_address *
ip_address - IP Address
IP Address

(header)	
client_id *
client_id - Client ID
Client ID

(header)	
client_secret *
client_secret - Client Secret
Client Secret

(header)	
username *
username - User name
User name

(header)	
auth-token *
auth-token - Token
Token

(header)	
gstin *
gstin - GSTIN number
GSTIN number

(header)	
Responses
Code	Description	Links
200	
Successful, Get Sync GSTIN From CP Details.

No links
404	
Not Found. If requested entity is not found or if requested API is not found.

No links
500	
Internal server error

****************************************************************************************************
Get B2C QR Code Details
Get B2C QR Code Details

Show/Hide|List Operations|Expand Operations
GET
​/einvoice​/qrcode
Get B2C QR Code Details

Get B2C QR Code Details

Parameters
Name	Value	Description	Parameter Type	Data Type
email *
email - User Email
User Email

(query)	
ip_address *
ip_address - IP Address
IP Address

(header)	
client_id *
client_id - Client ID
Client ID

(header)	
client_secret *
client_secret - Client Secret
Client Secret

(header)	
username *
username - User name
User name

(header)	
sgstin *
sgstin - Seller GSTIN Number
Seller GSTIN Number

(header)	
docno *
docno - Invoice Number
Invoice Number

(header)	
docdate *
docdate - Invoice Date (dd-MM-yyyy)
Invoice Date (dd-MM-yyyy)

(header)	
totinvval *
totinvval - Total Invoice Value
Total Invoice Value

(header)	
upiid
upiid - UPI Id
UPI Id

(header)	
bankaccno *
bankaccno - Seller Account Number
Seller Account Number

(header)	
bankifsccode *
bankifsccode - Bank IFSC Code
Bank IFSC Code

(header)	
accountholdername *
accountholdername - Account Holder Name
Account Holder Name

(header)	
igstamount *
igstamount - IGST Amount
IGST Amount

(header)	
cgstamount *
cgstamount - CGST Amount
CGST Amount

(header)	
sgstamount *
sgstamount - SGST Amount
SGST Amount

(header)	
cessamount *
cessamount - CESS Amount
CESS Amount

(header)	
Responses
Code	Description	Links
200	
Successful, Get B2C Qr Code Details.

No links
404	
Not Found. If requested entity is not found or if requested API is not found.

No links
500	
Internal server error



*************************api Error Code List************************

API Error codes List
Error Code	Error Messege	Reason for Error	Resolution
1004	Header GSTIN is required
1005	Invalid Token	1. Token has expired 2. While calling other APIs, wrong GSTIN / User Id/ Token passed in the request header	1. Token is valid for 6 hours , if it has expired, call the Auth. API again and get new token 2. Pass correct values for GSTIN, User Id and Auth Token in the request headers while calling APIs other than Auth API
1006	User Name is required
1007	Authentication failed. Pls. inform the helpdesk	Wrong formation of request payload	Prepare the request payload as per the API documentation
1008	Invalid login credentials	Either UserId or Password are wrong	Pass the correct UserId and Password
1010	Invalid Client-ID/Client-Secret	Either the ClientId or the ClientSecret passed in the request header is wrong	Pass the correct ClientId and the ClientSecret
1011	Client Id is required
1012	Client Secret is required
1013	Decryption of password failed	Auth.API is not able to decrypt the password	Use the correct public key for encrypting the password while calling the Auth API. The public key is sent by mail while providing the access to Production environment as well as available for download from the portal under API user management. This public key is different on Sandbox and Production and it is different from the one used for verification of the signed content.Refer to the developer portal for encryption method used and sample code.
1014	Inactive User	Status of the GSTIN is inactive or not enabled for E Invoice	Please verify whether the GSTIN is active and enabled for E Invoice from the E Invoice portal
1015	Invalid GSTIN for this user	The GSTIN of the user who has generated the auth token is different from the GSTIN being passed in the request header	Send the correct GSTIN in the header for APIs other than Auth API
1016	Decryption of App Key failed	Auth.API is not able to decrypt the password	Use the correct public key for encrypting the appkey while calling the Auth API. The public key is sent by mail while providing the access to Production environment as well as available for download from the portal under API user management. This public key is different on Sandbox and Production and it is different from the one used for verification of the signed content.Refer to the developer portal for encryption method used and sample code.
1017	Incorrect user id/User does not exists	User id passed in request payload is incorrect	Pass the correct user id. If not available, please log in to the portal using the main user id (the one without ')
1018	Client Id is not mapped to this user	The UserId is not mapped to the ClientId that is being sent as request header	Please send the correct userId for the respective clientId. If using direct integration as well as through GSP or through multiple GSPs, please pass the correct set of ClientId
1019	Incorrect Password	Password is wrong	Use the correct password, if forgotten, may use forgot password option in the portal
3001	Requested data is not available
3002	Invalid login credentials
3003	Password should contains atleast one upper case, one lower case, one number and one special characters like [%,$,#,@,_,!,*]	Password being set is very simple	Password should contains atleast one upper case, one lower case, one number and one special characters like [%,$]
3004	This username is already registered. Please choose a different username.	User id is already available in the system	Use a different user id
3005	Requested data is not found
3006	Invalid Mobile Number	The Mobile number provided is incorrect	Provide the correct mobile number, Incase the number has changed, may update it in GSTN Common Portal and try after some time. If issue still persists, contact helpdesk with complete details of the issue.
3007	You have exceeded the limit of creating sub-users	The number of sub user creation limit is exceeded	Up to 10 subusers for each of the main GSTIN and additional places of business can be created
3008	Sub user exists for this user id	There is already a subuser with the same user id is already created	Use a different user id for the sub user creation
3009	Pls provide the required parameter or payload
3010	The suffix login id should contain 4 or lesser than 4 characters
3011	Data not Found
3012	Mobile No. is blank for this GSTIN ..Pl use update from GST Common Portal option to get the mobile number, if updated in GST Common Portal.	The GSTIN master data does not have mobile number in eInvoice System	Please get the mobile number updated at the GSTN common portal
3013	Your registration under GST has been cancelled , however if you are a transporter then use the Enrollment option.
3014	Gstin Not Allowed
3015	Sorry, your GSTIN is deregistered in GST Common Portal	Attempting to use a GSTIN which is cancelled	Please check the status of the GSTIN on the GSTN common portal. If it is active, contact the helpdesk with GSTIN details
3016	Your registration under GST is inactive and hence you cannot register, however if you are a transporter then use the Enrollment option.
3017	You were given provisional ID which was not activated till the last date. Hence your details are not available with GST portal. However if you are a transporter then use the Enrollment option.
3019	subuser details are not saved please try again
3020	Internal Server Error pls try after sometime
3021	There are no subusers for this gstin	Some user action has failed due to internal server issue or unexpected user data	Try after some time, if issue still persists, report to helpdesk with complete details of the issue
3022	The Given Details Already Exists
3023	The New PassWord And Old PassWord Cannot Be Same	While changing the password, new password can not be same as old password	The New and Ols password should be different while changing the password
3024	Change of password unsuccessfull,pls check the existing password	Password could not be changed since the current password provided is incorrect	Provide the correct current password while changing the password
3025	Already This Account Has Been Freezed	Trying to freeze an account which is already frozen	You can freeze only active account
3027	You are already registered Pl.use already created username and password to login to the system.If you have forgotten username or password,then use Forgot Username or Forgot Passowrd options to get the username and password!!"	Attempting to create another account which is already created	Use forgot password option to retrieve the user name or password in case currently not available
3029	GSTIN is inactive or cancelled	GSTIN is inactive or cancelled by department or tax payer .	Check the correctness of the GSTIN and its status. If you are sure that it is active, Pl use the 'Sync GSTIN from GST CP' API to get it verified from the GST Portal. If it is active at GST portal, it will return you with the new status. If you get the status as 'Active', then you can re-fire your request to generate the IRN. If you are not able to verify through API, you can go to einvocie1.gst.gov.in portal and use the 'Tax Payer / GSTIN' option in search menu to check the status manually from GST Portal and use 'Update' button to get it updated from GST Common Portal, if required. If you are satisfied with result, you can re-fire the request.
3030	Invalid Gstin	GSTIN provided is incorrect	Provide the correct GSTIN
3031	Invalid User Name	Attempting to login with wrong user id	Use the correct user id
3032	Enrolled Transporter cannot login to e-Invoice Portal. You need to be GST registered. For more clarifications , please read the FAQs under Web Login section .	The user who is not registered with GSTN but enrolled as transporter in E Way Bill portal is trying to login to eInvoice system	This is not allowed
3033	Your account has been Freezed as GSTIN is inactive	User is trying to login with an account which is freezed since the GSTIN is not active	Check the status of the GSTIN on the GSTN common portal. If active in common portal, report the same to helpdesk
3034	Your account has been cancelled as GSTIN is inactive	User is trying to login with an account which is cancelled since the GSTIN is not active	Check the status of the GSTIN on the GSTN common portal. If active in common portal, report the same to helpdesk
3035	Your account has been suspended as GSTIN is inactive	User is trying to login with an account which is suspended since the GSTIN is not active	Check the status of the GSTIN on the GSTN common portal. If active in common portal, report the same to helpdesk
3036	Your account has been inactive	Attempting to logging with a user id which is not active	Check the status of the user id, if in freeze state, create a new account
3037	CommonEnrolled Transporter not allowed this site	A user with common enrolled opting is trying to use the eInvoice system	eInvoice system can not be used by the GSTIN which has opted for common enrolment under E Way Bill
3042	Invalid From Pincode or To Pincode	PIN code passed is wrong	Pass the correct PIN code. Check the PIN code on the portal under Search -> Master Codes
3043	Something went wrong, please try again after sometime	Attempting to carryout some on the system or passing some data which is not expected	Please check the data or the operation which you have just performed. If issue still persists, please share the complete details to the helpdesk
3044	This registration only for tax payers not GSP.	The option is available for the the Taxpayers and not for GSPs	This option is not available / applicable for GSP
3045	Sorry you are not registered, Please use the registration option.
3046	Sorry you are not enabled for e-Invoicing System on Production.	Ineligible taxpayer is trying to register for the eInvoice system	In case the turnover is above 500crores in any of the financial years in GST regime, use the enrol option in eInvoice portal
3052	Transporter Id {0} is cancelled or invalid.
3053	Unauthorised access
3058	Data not Saved
3059	Client-Id for this PAN is not generated check your IP-Whitelisting status.
3060	Please wait for officer approval
3061	Your Request has been rejected, please register again
3062	Already Registered
3063	You are already enabled for e-invoicing
3064	Sorry, This GSTIN is deregistered
3065	You are not allowed to use this feature.
3066	There is no pin codes availables for this state.
3067	Client secret unsuccessfull,pls check the existing client secret.
3068	There is no Api user.
3069	Sorry,you have not directly integrated with E-invoice API.
3070	Sorry,you have not registered.
3071	Sorry,you have already linked this Gstin to your Client Id.
3072	Sorry,Your GSTIN not enabled by the Direct Integrator.
3073	You are already registered.
3074	GSTIN - {0} is cancelled and document date - {1} is later than de-registration date
3075	GSTIN- {0} is cancelled and de-registration date is not available
3076	GSTIN - {0} is inactive
3077	GSTIN - {0} is cancelled and document date - {1} is earlier than registration date
3078	GSTIN- {0} is cancelled and registration date is not available
3079	For active GSTINs the document date should not be earlier than registration date
3080	Sorry, e-Invoicing cannot be enabled.
SYS_5001	Application error, issue with application while processing the request. Please try again. If error persists kindly raise a ticket along with request JSON, error details and timestamp of the error occurrence.
Ewaybill Errors
Error Code	Error Messege
1004	Header GSTIN is required
4000	Status of the IRN is not active
4001	Error ocurred while creating Eway Bill
4002	EwayBill is already generated for this IRN
4003	Requested IRN data is not available
4004	Error while retrieving IRN details
4005	Eway Bill details are not found
4006	Requesting parameter cannot be empty
4007	Requested e-Way Bill is not available
4008	Please enter valid e-waybill number
4009	E Way Bill can be generated provided at least HSN of one item belongs to goods.
4010	E-way Bill cannot generated for Debit Note, Credit Note and Services.
4011	Vehicle number should be passed in case of transportation mode is Road.
4012	The transport document number should be passed for transportation modes air and rail
4013	The distance between the pincodes given is too high or low.
4014	Invalid Vehicle Number
4015	EWayBill will not be generated for blocked User -{0}
4016	Transport document date cannot be a future date
4017	Incorrect date format
4018	Invalid Transporter ID
4019	Provide Transporter ID in order to generate Part A of e-Way Bill
4020	Invalid vehicle type .
4021	Transporter document date cannot be earlier than the invoice date.
4022	vehicle type should be passed in case of transportation mode is Road.
4023	The transport document date should be passed for of transportation modes air and rail.
4024	Vehicle type should not be ODC when transmode is other than road and ship
4025	Invalid User-Id
4026	Duplicate EwayBill for the given document numer, EwbNo - ({0})
4027	Transporter Id is mandatory for generation of Part A slip
4028	Transport mode is mandatory as Vehicle Number/Transport Document Number is given
4029	Valid distance to be sent in case of same pin codes, you cannot send 0 as distance in this case.
4030	The distance between the pincodes {0} and {1} is not available in the system, you need to pass the actual distance.
4031	Ship to details are mandatory for export transactions to generate e-Way Bill.
4032	Ship to state code cannot be other country code(96) for e-Way Bill generation
4033	Ship to PIN code cannot be 999999 for e-Way Bill generation
4034	Since the you passed Supplier/Recepient/Dispatch from/Ship to Pincode as 999999, distance cannot be 0
4035	Dispatch state code cannot be other country code(96) for e-Way Bill generation
4036	Dispatch PIN code cannot be 999999 for e-Way Bill generation
4037	You are not authorised to get data
4038	The distance between the pincodes given is too high
4039	Vehicle type can not be regular when transport mode is ship
4040	For Ship Transport, either vehicle number or transport document number is required