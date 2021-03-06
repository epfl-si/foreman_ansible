# frozen_string_literal: true

module ForemanAnsible
  module AnsibleRolesDataPreparations
    VARIABLE_ACTION_NAMES = { 'new' => N_('Add'), 'obsolete' => N_('Remove'), 'update' => N_('Update') }.freeze
    ROLE_ACTION_NAMES = { 'new' => N_('Import Role'), 'obsolete' => N_('Remove Role'), 'old' => N_('Update Role Variables') }.freeze

    def get_variable_action(kind)
      _(VARIABLE_ACTION_NAMES[kind])
    end

    def get_role_action(kind)
      _(ROLE_ACTION_NAMES[kind])
    end

    def get_old_roles_variables(imported_variables, role)
      variables = { 'Add' => [], 'Remove' => [], 'Update' => [] }
      imported_variables.each do |kind, temp_variables|
        temp_variables.each do |temp_variable|
          variables[get_variable_action(kind)].append(temp_variable.key) if temp_variable.ansible_role_id == role.id
        end
      end
      variables
    end

    def variables_to_s(variables)
      str = ''
      variables.each do |action, temp_variables|
        str += "#{action}: #{temp_variables.size}, " unless temp_variables.empty?
      end
      str[0..-3]
    end

    def get_roles_variables(imported_variables, variables_importer, kind, role)
      if kind == 'new'
        variables = { 'Add' => variables_importer.get_variables_names(role.name) }
      elsif kind == 'obsolete'
        variables = { 'Remove' => role.ansible_variables.map(&:key) }
      elsif kind == 'old'
        variables = get_old_roles_variables(imported_variables, role)
      end
      variables_to_s(variables)
    end

    def prepare_ansible_import_rows(changed, variables_importer)
      rows = []
      changed.each do |kind, roles|
        imported_variables = variables_importer.import_variable_names(roles)
        roles.each do |role|
          role_action = get_role_action(kind)
          variables = get_roles_variables(imported_variables, variables_importer, kind, role)
          next if variables.empty? && kind['old']
          rows.append({ cells: [
                        role.name,
                        role_action, variables,
                        role_action == 'Remove Role' ? role.hosts.count : '',
                        role_action == 'Remove Role' ? role.hostgroups.count : ''
                      ],
                        role: role, kind: kind, id: role.name })
        end
      end
      rows
    end
  end
end
