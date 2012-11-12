def stub_columns_for_rails31(connection)
  return unless DbCharmer.rails31?
  connection.abstract_connection_class.retrieve_connection.stub(:columns).and_return([])
end
