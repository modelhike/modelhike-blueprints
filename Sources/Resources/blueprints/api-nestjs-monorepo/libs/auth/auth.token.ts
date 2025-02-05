//import * as bcrypt from 'bcrypt';
import { ExtendedReference, Reference } from 'libs/domain-models/common.classes';

export class UserSessionJwt {
  userRef?: string;
  userDisp?: string;
  loginId?: string;
  userAvatar?: string;
  role?: string;
  type?: string;

  constructor(payload: any) {
    // (this.userRef = payload.userRef),
    //   (this.userDisp = payload.userDisp),
    //   (this.loginId = payload.loginId),
    //   (this.role = payload.role),
    //   (this.userAvatar = payload.userAvatar),
    //   (this.type = payload.type);
  }

  public getUserRef(): Reference {
    const obj = new Reference();
    obj.ref = this.userRef;
    obj.display = this.userDisp;
    return obj;
  }

  public getUserExtendedRef(): ExtendedReference {
    const obj = new ExtendedReference();
    obj.ref = this.userRef;
    obj.display = this.userDisp;
    obj.avatar = this.userAvatar;
    return obj;
  }

  public isGuestToken(): boolean {
    return this.type === 'guest';
  }
}

