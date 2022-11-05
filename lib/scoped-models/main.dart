import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/scoped-models/cart_scope_model.dart';
import 'package:sheraccerp/scoped-models/company_scope_model.dart';
import 'package:sheraccerp/scoped-models/customer_scope_model.dart';
import 'package:sheraccerp/scoped-models/user_scope_model.dart';

class MainModel extends Model
    with
        UserScopeModel,
        CartScopeModel,
        CustomerScopeModel,
        CompanyScopeModel {}
