export class UserRoles {
  static SUPER_ADMIN: string = 'superadmin';
  static EMPLOYEE: string = 'employee';

  static roles: string[] = [
    this.SUPER_ADMIN,
    this.EMPLOYEE,
  ];

  static isSuperAdmin(role: string): boolean {
    return role === this.SUPER_ADMIN;
  }

}