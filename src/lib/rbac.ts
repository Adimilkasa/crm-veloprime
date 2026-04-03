import {
  BadgeCheck,
  BadgePercent,
  BriefcaseBusiness,
  FileText,
  LayoutDashboard,
  type LucideIcon,
  ShieldCheck,
} from 'lucide-react'

export type UserRoleKey = 'ADMIN' | 'DIRECTOR' | 'MANAGER' | 'SALES'

export type RoleDefinition = {
  key: UserRoleKey
  label: string
  description: string
}

export type NavigationItem = {
  href: string
  label: string
  icon: LucideIcon
  roles: UserRoleKey[]
}

export const roleDefinitions: RoleDefinition[] = [
  {
    key: 'ADMIN',
    label: 'Administrator',
    description: 'Zarządza kontami, konfiguracją, flotą i polityką cenową.',
  },
  {
    key: 'DIRECTOR',
    label: 'Dyrektor',
    description: 'Ma wgląd w wyniki, marże, pipeline i pracę całego zespołu.',
  },
  {
    key: 'MANAGER',
    label: 'Manager',
    description: 'Prowadzi zespół, przypisuje leady i nadzoruje oferty.',
  },
  {
    key: 'SALES',
    label: 'Handlowiec',
    description: 'Obsługuje klientów, leady i przygotowuje oferty online.',
  },
]

export const navigationItems: NavigationItem[] = [
  {
    href: '/dashboard',
    label: 'Dashboard',
    icon: LayoutDashboard,
    roles: ['ADMIN', 'DIRECTOR', 'MANAGER', 'SALES'],
  },
  {
    href: '/leads',
    label: 'Leady',
    icon: BadgeCheck,
    roles: ['ADMIN', 'DIRECTOR', 'MANAGER', 'SALES'],
  },
  {
    href: '/offers',
    label: 'Oferty',
    icon: FileText,
    roles: ['ADMIN', 'DIRECTOR', 'MANAGER', 'SALES'],
  },
  {
    href: '/commissions',
    label: 'Prowizje',
    icon: BadgePercent,
    roles: ['ADMIN', 'DIRECTOR', 'MANAGER'],
  },
  {
    href: '/users',
    label: 'Użytkownicy',
    icon: ShieldCheck,
    roles: ['ADMIN'],
  },
  {
    href: '/pricing',
    label: 'Polityka cenowa',
    icon: BriefcaseBusiness,
    roles: ['ADMIN', 'DIRECTOR'],
  },
  {
    href: '/colors',
    label: 'Palety kolorow',
    icon: BadgeCheck,
    roles: ['ADMIN', 'DIRECTOR'],
  },
]

export function getRoleDefinition(role: UserRoleKey) {
  return roleDefinitions.find((definition) => definition.key === role) ?? roleDefinitions[0]
}

export function getNavigationForRole(role: UserRoleKey) {
  return navigationItems.filter((item) => item.roles.includes(role))
}