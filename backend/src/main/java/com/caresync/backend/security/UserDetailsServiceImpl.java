package com.caresync.backend.security;

import com.caresync.backend.modules.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String identifier) throws UsernameNotFoundException {
        String cleanIdentifier = identifier != null ? identifier.trim() : "";
        return userRepository.findByEmailOrUsernameIgnoreCase(cleanIdentifier)
                .orElseThrow(() -> new UsernameNotFoundException("Invalid email/username or password."));
    }
}
